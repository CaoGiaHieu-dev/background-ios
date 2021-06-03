#import "GmoCallkitServicePlugin.h"
#if __has_include(<gmo_callkit_service/gmo_callkit_service-Swift.h>)
#import <gmo_callkit_service/gmo_callkit_service-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "gmo_callkit_service-Swift.h"
#endif

@implementation GmoCallkitServicePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGmoCallkitServicePlugin registerWithRegistrar:registrar];
}
@end
