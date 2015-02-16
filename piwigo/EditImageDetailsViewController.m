//
//  EditImageDetailsViewController.m
//  piwigo
//
//  Created by Spencer Baker on 2/8/15.
//  Copyright (c) 2015 bakercrew. All rights reserved.
//

#import "EditImageDetailsViewController.h"
#import "EditImageTextFieldTableViewCell.h"
#import "EditImageTextViewTableViewCell.h"
#import "EditImageLabelTableViewCell.h"
#import "ImageUpload.h"
#import "SelectPrivacyViewController.h"

typedef enum {
	EditImageDetailsOrderImageName,
	EditImageDetailsOrderAuthor,
	EditImageDetailsOrderPrivacy,
	EditImageDetailsOrderTags,
	EditImageDetailsOrderDescription,
	EditImageDetailsOrderCount
} EditImageDetailsOrder;

@interface EditImageDetailsViewController () <UITableViewDelegate, UITableViewDataSource, SelectPrivacyDelegate>

@property (weak, nonatomic) IBOutlet UITableView *editImageDetailsTableView;

@end

@implementation EditImageDetailsViewController

-(void)awakeFromNib
{
	[super awakeFromNib];
	
	self.title = @"Edit Image Details";
}

-(void)viewWillDisappear:(BOOL)animated
{
	if([self.delegate respondsToSelector:@selector(didFinishEditingDetails:)])
	{
		[self updateImageDetails];
		[self.delegate didFinishEditingDetails:self.imageDetails];
	}
}

-(void)updateImageDetails
{
	EditImageTextFieldTableViewCell *textFieldCell = (EditImageTextFieldTableViewCell*)[self.editImageDetailsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:EditImageDetailsOrderImageName inSection:0]];
	self.imageDetails.imageUploadName = textFieldCell.getTextFieldText;
	
	textFieldCell = (EditImageTextFieldTableViewCell*)[self.editImageDetailsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:EditImageDetailsOrderAuthor inSection:0]];
	self.imageDetails.author = textFieldCell.getTextFieldText;
	
	EditImageTextViewTableViewCell *textViewCell = (EditImageTextViewTableViewCell*)[self.editImageDetailsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:EditImageDetailsOrderDescription inSection:0]];
	self.imageDetails.imageDescription = textViewCell.getTextViewText;
}

#pragma mark UITableView methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == EditImageDetailsOrderDescription) return 100.0;
	return 44.0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return EditImageDetailsOrderCount;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [UITableViewCell new];
	
	switch(indexPath.row)
	{
		case EditImageDetailsOrderImageName:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:@"textField"];
			[((EditImageTextFieldTableViewCell*)cell) setLabel:@"Image Name" andTextField:self.imageDetails.imageUploadName withPlaceholder:@"Image Name"];
			break;
		}
		case EditImageDetailsOrderAuthor:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:@"textField"];
			[((EditImageTextFieldTableViewCell*)cell) setLabel:@"Author" andTextField:self.imageDetails.author withPlaceholder:@"Author Name"];
			break;
		}
		case EditImageDetailsOrderPrivacy:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:@"label"];
			[((EditImageLabelTableViewCell*)cell) setPrivacyLevel:self.imageDetails.privacyLevel];
			break;
		}
		case EditImageDetailsOrderTags:
		{
			break;
		}
		case EditImageDetailsOrderDescription:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:@"textArea"];
			break;
		}
	}
	
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if(indexPath.row == EditImageDetailsOrderPrivacy)
	{
		SelectPrivacyViewController *privacySelectVC = [SelectPrivacyViewController new];
		privacySelectVC.delegate = self;
		[privacySelectVC setPrivacy:self.imageDetails.privacyLevel];
		[self.navigationController pushViewController:privacySelectVC animated:YES];
	}
}

#pragma mark SelectPrivacyDelegate Methods

-(void)selectedPrivacy:(kPiwigoPrivacy)privacy
{
	self.imageDetails.privacyLevel = privacy;
	
	EditImageLabelTableViewCell *labelCell = (EditImageLabelTableViewCell*)[self.editImageDetailsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:EditImageDetailsOrderPrivacy inSection:0]];
	[labelCell setPrivacyLevel:privacy];
}

@end
