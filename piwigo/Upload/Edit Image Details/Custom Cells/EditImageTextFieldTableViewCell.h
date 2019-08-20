//
//  EditImageTextFieldTableViewCell.h
//  piwigo
//
//  Created by Spencer Baker on 2/8/15.
//  Copyright (c) 2015 bakercrew. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditImageTextFieldTableViewCell : UITableViewCell

-(void)paletteChanged;
-(void)setLabel:(NSString*)label andTextField:(NSString*)text withPlaceholder:(NSString*)placeholder;
-(NSString *)getTextFieldText;
-(BOOL)isEditingTextField;
-(CGFloat)getTextFieldHeight;

@end
