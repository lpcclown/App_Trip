//
//  PickerViewDataSourceParent.h
//  FloridaTripTracker
//
//  Created by Benaiah Pitts on 2/2/15.
//
//

#ifndef FloridaTripTracker_PickerViewDataSourceParent_h
#define FloridaTripTracker_PickerViewDataSourceParent_h

@protocol PickerViewDataSourceParent <NSObject>

@required
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

@end

#endif
