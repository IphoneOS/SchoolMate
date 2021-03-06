//
//  BBNewspaperViewController.m
//  SchoolMate
//
//  Created by libiwu on 15/6/8.
//  Copyright (c) 2015年 libiwu. All rights reserved.
//

#import "BBNewspaperViewController.h"
#import "NewspaperTableViewCell.h"
#import "SMNavigationPopView.h"
#import "BBNewspaperDetailViewController.h"
#import "BBPublishViewController.h"
#import "BBNPClassModel.h"
#import "BBNPModel.h"

static NSString *const reuseIdentity = @"Cell";

@interface BBNewspaperViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView         *tableView;
@property (strong, nonatomic) SMNavigationPopView *navPopView;

/*黑板报班级列表*/
//黑板报班级列表：班级model
@property (strong, nonatomic) NSMutableArray      *bbnpClassArray;
//黑板报班级列表：班级名字
@property (nonatomic, strong) NSArray *bbnpClassTitleArray;
///当前选择的黑板报id
@property (copy, nonatomic) NSString *boardId;

/*黑板报列表*/
@property (nonatomic, strong) NSArray *dataArray;
///cell高度
@property (strong, nonatomic) NSMutableArray *cellHeightArray;
@end

@implementation BBNewspaperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _cellHeightArray = [NSMutableArray array];
    
    [self creatContentView];
    
    [self requestGetClassList];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kPublishComplete
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.tableView.header beginRefreshing];
                                                  }];
}

- (void)creatContentView {
    self.view.backgroundColor = RGBACOLOR(234.0, 234.0, 234.0, 1.0);
    
    [self setLeftMenuTitle:nil andnorImage:@"26" selectedImage:@"26"];
    [self setRightMenuTitle:nil andnorImage:@"27" selectedImage:@"27"];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, KScreenHeight-64-49) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.dataSource      = self;
    _tableView.delegate        = self;
    _tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"NewspaperTableViewCell" bundle:nil] forCellReuseIdentifier:reuseIdentity];
    [self.view addSubview:_tableView];
    
    WEAKSELF
    [self.tableView addLegendHeaderWithRefreshingBlock:^{
        [weakSelf requestBlackboardListWithBoardId:weakSelf.boardId upOrDown:@"0"];
    }];
    [self.tableView addLegendFooterWithRefreshingBlock:^{
        [weakSelf requestBlackboardListWithBoardId:weakSelf.boardId upOrDown:@"1"];
    }];
}
#pragma mark -
- (void)configureNavTitleData {
    /**
     {"schoolTypeId":1,"name":"小学"},
     {"schoolTypeId":2,"name":"初中"},
     {"schoolTypeId":3,"name":"高中"},
     {"schoolTypeId":4,"name":"大学"}
     */
    __block NSMutableArray *tempArr = [NSMutableArray array];
    [self.bbnpClassArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BBNPClassModel *model = obj;
        if ([model.schoolType integerValue] != 4) {
            //显示班级
            [tempArr addObject:model.className];
        }
        else {
            //显示学校名
            [tempArr addObject:model.schoolName];
        }
    }];
    self.bbnpClassTitleArray = tempArr;
    if (tempArr.count) {
        [self setNavTitle:self.bbnpClassTitleArray[0] type:SCNavTitleTypeSelect];
        BBNPClassModel *model = self.bbnpClassArray.firstObject;
        _boardId = model.boardId.stringValue;
        [self requestBlackboardListWithBoardId:_boardId upOrDown:@"0"];
    }
    
}

- (void)navigationClick:(UIButton *)btn {
    _navPopView = [[SMNavigationPopView alloc] initWithDataArray:self.bbnpClassTitleArray];
    WEAKSELF
    [_navPopView setTableViewSelectBlock:^(NSUInteger index, NSString *string) {
        [weakSelf setNavTitle:string type:SCNavTitleTypeSelect];
        BBNPClassModel *model = weakSelf.bbnpClassArray[index];
        _boardId = model.boardId.stringValue;
        [weakSelf requestBlackboardListWithBoardId:weakSelf.boardId upOrDown:@"0"];
    }];
    [_navPopView show];
}

- (void)leftMenuPressed:(id)sender {
    BBPublishViewController *vc = [[BBPublishViewController alloc] initWithHiddenTabBar:YES hiddenBackButton:NO];
    vc.boardId = _boardId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)rightMenuPressed:(id)sender {
    
}


#pragma mark - 计算高度
- (void)figureHeightWithData:(NSArray *)array {
    
    [_cellHeightArray removeAllObjects];
    
    for (BBNPModel *model in array) {
        CGFloat height = [NewspaperTableViewCell configureCellHeightWithModel:model];
        //存储高度
        [_cellHeightArray addObject:@(height)];
    }
    //数据保存完之后刷新界面
    [_tableView reloadData];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewspaperTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentity forIndexPath:indexPath];
    BBNPModel *model = _dataArray[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setContentWithModel:model];
    [cell setCommentAction:^(UIButton *btn) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
    }];
    [cell setSupportAction:^(UIButton *btn) {
        if ([model.isLike isEqualToString:@"0"]) {
            btn.enabled = NO;
            [self requestSupport:indexPath complete:^(BOOL success) {
                btn.enabled = YES;
            }];
        } else {
            btn.enabled = NO;
            [self requestDeleteSupport:indexPath complete:^(BOOL success) {
                btn.enabled = YES;
            }];
        }
    }];
    [cell setDeleteAction:^(UIButton *btn) {
        [self requestDeleteBlog:indexPath];
    }];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BBNewspaperDetailViewController *vc = [[BBNewspaperDetailViewController alloc]initWithHiddenTabBar:YES hiddenBackButton:NO];
    vc.bbnpModel = _dataArray[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_cellHeightArray[indexPath.row] floatValue];
}

#pragma mark - Request
#pragma mark 黑板报班级列表
- (void)requestGetClassList {
    WEAKSELF
    [[AFHTTPRequestOperationManager manager] POST:kSMUrl(@"/classmate/m/board/list")
                                       parameters:@{@"userId" : [GlobalManager shareGlobalManager].userInfo.userId}
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              NSString *success = [Tools filterNULLValue:responseObject[@"success"]];
                                              if ([success isEqualToString:@"1"]) {
                                                  
                                                  __block NSMutableArray *newArray = [NSMutableArray array];
                                                  [responseObject[@"data"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                      BBNPClassModel *model = [BBNPClassModel objectWithKeyValues:obj];
                                                      [newArray addObject:model];
                                                  }];
                                                  weakSelf.bbnpClassArray = newArray;
                                                  [weakSelf configureNavTitleData];
                                              } else {
                                                  NSString *string = [Tools filterNULLValue:responseObject[@"message"]];
                                                  [SMMessageHUD showMessage:string afterDelay:2.0];
                                              }
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              [SMMessageHUD showMessage:@"网络错误" afterDelay:1.0];
                                          }];
}

#pragma mark 黑板报博客列表
/**
 *  @author libiwu, 15-07-02 02:07
 *
 *  请求黑板报博客列表
 *
 *  @param boardId     班级id
 *  @param requestType 0:下拉刷新或第一次请求 1:加载更多
 */
- (void)requestBlackboardListWithBoardId:(NSString *)boardId upOrDown:(NSString *)requestType{
    /*
     Param: {
     userId :  1     （必填，当前用户ID）
     boardId : 1    （必填，黑板报ID）
     orderBy : addTime  （选填，排序字段，默认为addTime - 微博添加时间）
     orderType : desc   （选填，排序顺序，"desc" - 倒序 或者 "asc" - 升序，默认为desc）
     offset : 0         （选填，记录开始索引，默认为0）
     limit : 2          （选填，返回记录数，默认为5）
     }
     */
    WEAKSELF
    NSString *offset = [NSString stringWithFormat:@"%lu",requestType.integerValue == 0 ? 0 : self.dataArray.count];
    NSString *limit = [NSString stringWithFormat:@"%lu",requestType.integerValue == 0 ? 5 : self.dataArray.count + 5];
    [[AFHTTPRequestOperationManager manager] POST:kSMUrl(@"/classmate/m/board/blog/list")
                                       parameters:@{@"userId" : [GlobalManager shareGlobalManager].userInfo.userId,
                                                    @"boardId" : boardId,
                                                    @"orderBy" : @"addTime",
                                                    @"orderType" : @"desc",
                                                    @"offset" : offset,
                                                    @"limit" : limit}
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              NSString *success = [Tools filterNULLValue:responseObject[@"success"]];
                                              if ([success isEqualToString:@"1"]) {
                                                  __block NSMutableArray *newArray = nil;
                                                  if (requestType.integerValue == 0) {
                                                      newArray = [NSMutableArray array];
                                                  } else {
                                                      newArray = [NSMutableArray arrayWithArray:self.dataArray];
                                                  }
                                                  [responseObject[@"data"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                      BBNPModel *model = [BBNPModel objectWithKeyValues:obj];
                                                      [newArray addObject:model];
                                                  }];
                                                  weakSelf.dataArray = newArray;
                                                  [weakSelf figureHeightWithData:newArray];
                                              } else {
                                                  NSString *string = [Tools filterNULLValue:responseObject[@"message"]];
                                                  [SMMessageHUD showMessage:string afterDelay:2.0];
                                              }
                                              [weakSelf.tableView.header endRefreshing];
                                              [weakSelf.tableView.footer endRefreshing];
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              [SMMessageHUD showMessage:@"网络错误" afterDelay:1.0];
                                              [weakSelf.tableView.header endRefreshing];
                                              [weakSelf.tableView.footer endRefreshing];
                                          }];
}
#pragma mark 稀饭（点赞）
- (void)requestSupport:(NSIndexPath *)indexPath complete:(void(^)(BOOL success))complete {
    /*
     Param: {
     userId:1　　　　　　　 （必填，当前用户ID）
     boardBlogId:2　　　　　（必填，黑板报博客ID）
     }
     */
    
    NewspaperTableViewCell *cell = (NewspaperTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    BBNPModel *model = self.dataArray[indexPath.row];
    cell.likeCountLab.text = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue + 1];
    [[AFHTTPRequestOperationManager manager] POST:kSMUrl(@"/classmate/m/board/blog/like/save")
                                       parameters:@{@"userId" : [GlobalManager shareGlobalManager].userInfo.userId,
                                                    @"boardBlogId" : model.boardBlogId}
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              NSString *success = [Tools filterNULLValue:responseObject[@"success"]];
                                              if ([success isEqualToString:@"1"]) {
                                                  //表示已赞
                                                  model.isLike = @"1";
                                                  model.likeCount = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue + 1];
                                                  if (complete) {
                                                      complete(NO);
                                                  }
                                              } else {
                                                  if (complete) {
                                                      complete(NO);
                                                  }
                                                  cell.likeCountLab.text = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue - 1];
                                                  NSString *string = [Tools filterNULLValue:responseObject[@"message"]];
                                                  [SMMessageHUD showMessage:string afterDelay:2.0];
                                              }
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              if (complete) {
                                                  complete(NO);
                                              }
                                              cell.likeCountLab.text = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue - 1];
                                              [SMMessageHUD showMessage:@"网络错误" afterDelay:1.0];
                                          }];
}
- (void)requestDeleteSupport:(NSIndexPath *)indexPath complete:(void(^)(BOOL success))complete{
    /*
     Param: {
     userId:1　　　　　　　 （必填，当前用户ID）
     boardBlogId:2　　　　　（必填，黑板报博客ID）
     }
     */
    
    NewspaperTableViewCell *cell = (NewspaperTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    BBNPModel *model = self.dataArray[indexPath.row];
    cell.likeCountLab.text = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue - 1];
    [[AFHTTPRequestOperationManager manager] POST:kSMUrl(@"/classmate/m/board/blog/like/delete")
                                       parameters:@{@"userId" : [GlobalManager shareGlobalManager].userInfo.userId,
                                                    @"boardBlogId" : model.boardBlogId}
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              NSString *success = [Tools filterNULLValue:responseObject[@"success"]];
                                              if ([success isEqualToString:@"1"]) {
                                                  //表示已取消赞
                                                  model.isLike = @"0";
                                                  model.likeCount = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue - 1];
                                                  if (complete) {
                                                      complete(YES);
                                                  }
                                              } else {
                                                  cell.likeCountLab.text = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue + 1];
                                                  NSString *string = [Tools filterNULLValue:responseObject[@"message"]];
                                                  [SMMessageHUD showMessage:string afterDelay:2.0];
                                                  if (complete) {
                                                      complete(NO);
                                                  }
                                              }
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              cell.likeCountLab.text = [NSString stringWithFormat:@"%ld",model.likeCount.integerValue + 1];
                                              [SMMessageHUD showMessage:@"网络错误" afterDelay:1.0];
                                              if (complete) {
                                                  complete(NO);
                                              }
                                          }];
}
#pragma mark 删除博客
- (void)requestDeleteBlog:(NSIndexPath *)indexPath {
    /*
     Request URL:http://120.24.169.36:8080/classmate/m/board/blog/delete
     Request Method:POST
     Param: {
     userId:1     （必填，当前用户ID）
     boardBlogId:1    （必填，黑板报博客ID）
     }
     */
    [SMMessageHUD showLoading:@""];
    BBNPModel *model = self.dataArray[indexPath.row];
    [[AFHTTPRequestOperationManager manager] POST:kSMUrl(@"/classmate/m/board/blog/delete")
                                       parameters:@{@"userId" : [GlobalManager shareGlobalManager].userInfo.userId,
                                                    @"boardBlogId" : model.boardBlogId}
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              [SMMessageHUD dismissLoading];
                                              NSString *success = [Tools filterNULLValue:responseObject[@"success"]];
                                              if ([success isEqualToString:@"1"]) {
                                                  NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataArray];
                                                  [array removeObjectAtIndex:indexPath.row];
                                                  self.dataArray = array;
                                                  [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                              } else {
                                                  NSString *string = [Tools filterNULLValue:responseObject[@"message"]];
                                                  [SMMessageHUD showMessage:string afterDelay:2.0];
                                              }
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              [SMMessageHUD dismissLoading];
                                              [SMMessageHUD showMessage:@"网络错误" afterDelay:1.0];
                                          }];
}
@end
