//
//  WBBladesLinkManager.m
//  WBBlades
//
//  Created by 邓竹立 on 2019/6/15.
//  Copyright © 2019 邓竹立. All rights reserved.
//

#import "WBBladesLinkManager.h"
#import <mach-o/nlist.h>

#import "WBBladesObjectHeader.h"
#import "WBBladesSymTab.h"
#import "WBBladesStringTab.h"
#import "WBBladesObject.h"

#define SYMBOL_TABLE @"symbol_tab"
#define STRING_TABLE @"string_tab"

//extern unsigned long symSize;
//extern unsigned long stringSize;

typedef struct wb_objc_classdata {
    long long flags;
    long long instanceStart;
    long long instanceSize;
    long long reserved;
    unsigned long long ivarlayout;
    unsigned long long name;
    unsigned long long baseMethod;
    unsigned long long baseProtocol;
    unsigned long long ivars;
    unsigned long long weakIvarLayout;
    unsigned long long baseProperties;
} wb_objc_classdata;

@interface WBBladesLinkManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableSet*> *unixData;

@property (nonatomic, assign) unsigned long long linkSize;

@property (nonatomic, strong) NSMutableSet *abandonStringSet;

@end

@implementation WBBladesLinkManager

+ (WBBladesLinkManager *)shareInstance {
    static WBBladesLinkManager* linker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        linker = [[WBBladesLinkManager alloc] init];
        linker.unixData = [NSMutableDictionary dictionary];
        linker.abandonStringSet = [NSMutableSet set];
    });
    return linker;
}

- (unsigned long long)linkWithObjects:(NSArray<WBBladesObject *>*)objects {
    self.linkSize = 0;
    for (WBBladesObject *object in objects) {
        self.linkSize += object.objectMachO.size;

        // 对section进行链接
        [object.objectMachO.sections enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray * _Nonnull section, BOOL * _Nonnull stop) {
            if (!self.unixData[key]) {
                self.unixData[key] = [NSMutableSet set];
            }

            NSMutableSet *set = self.unixData[key];
            for (id value in section) {
                int scale = [key isEqualToString:@"(__TEXT,__ustring)"] ? 2 : 1;
                if ([set containsObject:value]) {
                    self.linkSize -= [value length] * scale;
                }
                [set addObject:value];
            }
        }];
    }
    return self.linkSize;
}

- (void)clearLinker {
    self.unixData = nil;
    self.unixData = [NSMutableDictionary dictionary];
    self.linkSize = 0;
    self.abandonStringSet = nil;
    self.abandonStringSet = [NSMutableSet set];
}

@end
/*
 http://chuquan.me/2020/09/14/mach-o-format/
 S_REGULAR：表示 section 没有特殊类型。标准工具创建的 __TEXT,__text 就是此类 section。
 S_ZEROFILL：按需填充零，当首次读取或写入该 section 时，其中的每个页面都会自动填充零。
 S_CSTRING_LITERALS：表示 section 只包含常量 C 字符传。标准工具创建的 __TEXT,__cstring 就是此类 section。
 S_4BYTE_LITERALS：表示 section 只包含 4 字节长的常量值。标准工具创建的 __TEXT,__literal4 就是此类 section。
 S_8BYTE_LITERALS：表示 section 只包含 8 字节长的常量值。标准工具创建的 __TEXT,__literal8 就是此类 section。
 S_NON_LAZY_SYMBOL_POINTERS：表示 section 只包含符号的非惰性指针。标准工具创建的 __DATA,__nl_symbol_ptrs 就是此类 section。
 S_LAZY_SYMBOL_POINTERS：表示 section 只包含符号的惰性指针。标准工具创建的 __DATA,__la_symbol_ptrs 就是此类 section。
 S_SYMBOL_STUBS：表示 section 只包含符号插桩（stub）。标准工具创建的 __TEXT,__symbol_stub 和 __TEXT,__picsymbol_stub 就是此类 section。
 S_MOD_INIT_FUNC_POINTERS：表示 section 只包含指向模块构建方法的指针。标准工具创建的 __DATA,__mod_init_func 就是此类 section。
 S_MOD_TERM_FUNC_POINTERS：表示 section 只包含指向模块析构方法的指针。标准工具创建的 __DATA,__mod_term_func 就是此类 section。
 S_COALESCED：表示 section 只包含由静态链接器或动态链接器合并的符号。多个文件包含同一符号的合并定义，而不会引起 multiple-defined-symbol 报错。
 S_GB_ZEROFILL：表示 section 是一个按需填充零的 section。section 可以大于 4 GB。该 section 只能放在仅包含零填充 section 的 segment 中。如果将零填充 section 放在包含非零填充 section 的 segment 中，那么可能会导致这些 section 无法没读取。最终导致静态链接器无法生成输出文件。
 
 ection 的属性有以下这些：
 S_ATTR_PURE_INSTRUCTIONS：表示 section 只包含可执行机器码。标准工具会为 __TEXT,__text、__TEXT,__symbol_stub、__TEXT,__picsymbol_stub 等 section 设置该属性。
 S_ATTR_SOME_INSTRUCTIONS：表示 section 包含一部分可执行机器码。
 S_ATTR_NO_TOC：表示 section 包含合并符号。
 S_ATTR_EXT_RELOC：表示 section 包含必须要被重定位的引用。这些引用引用其他文件中的数据（未定义符号）。为了支持外部重定位，包含此 section 的 segment 的最大虚拟内存保护级别必须允许读取和写入。
 S_ATTR_LOC_RELOC：表示 section 包含的引用必须被重定位。它们引用的是此文件中的数据。
 S_ATTR_STRIP_STATIC_SYMS：如果镜像的 mach_header 中的 MH_DYLDLINK 标志位被设置了，那么 section 中的静态符号就可以被删除。
 S_ATTR_NO_DEAD_STRIP：表示 section 的内容如果没有被引用，不能被删除。
 S_ATTR_LIVE_SUPPORT：如果 section 引用的代码存在，但是无法检测到该引用，那么不能被删除
 */
 
/*
__TEXT.__text    主程序代码
__TEXT.__cstring    C 语言字符串
__TEXT.__const    const 关键字修饰的常量
__TEXT.__stubs    用于 Stub 的占位代码，很多地方称之为桩代码。
__TEXT.__stubs_helper    当 Stub 无法找到真正的符号地址后的最终指向
__TEXT.__objc_methname    Objective-C 方法名称
__TEXT.__objc_methtype    Objective-C 方法类型
__TEXT.__objc_classname    Objective-C 类名称
__DATA.__data    初始化过的可变数据
__DATA.__la_symbol_ptr    lazy binding 的指针表，表中的指针一开始都指向 __stub_helper
__DATA.nl_symbol_ptr    非 lazy binding 的指针表，每个表项中的指针都指向一个在装载过程中，被动态链机器搜索完成的符号
__DATA.__const    没有初始化过的常量
__DATA.__cfstring    程序中使用的 Core Foundation 字符串（CFStringRefs）
__DATA.__bss    BSS，存放为初始化的全局变量，即常说的静态内存分配
__DATA.__common    没有初始化过的符号声明
__DATA.__objc_classlist    Objective-C 类列表
__DATA.__objc_protolist    Objective-C 原型
__DATA.__objc_imginfo    Objective-C 镜像信息
__DATA.__objc_selfrefs    Objective-C self 引用
__DATA.__objc_protorefs    Objective-C 原型引用
__DATA.__objc_superrefs    Objective-C 超类引用
*/
