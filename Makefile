DEBUG		= 1
#多目录用空格分开
DIR_SRC		= ./src
DIR_INC 	= ./include 
DIR_OBJ		= ./bin
DIR_LIB		= ./lib
TARGET  	= frida-gum-example
TARGET_SO	=cmodule
CC      := /root/data/lib/AndroidToolChain3/bin/aarch64-linux-android-gcc
LIBS    :=dl log m
LIBS_STATIC    := frida-gum
LDFLAGS :=
DEFINES :=

SRCS_CPP = $(foreach dir, $(DIR_SRC), $(wildcard $(dir)/*.cpp))
SRCS_C = $(foreach dir, $(DIR_SRC), $(wildcard $(dir)/*.c))
SOURCE := $(SRCS_CPP) $(SRCS_C)
#SOURCE  := $(wildcard $(DIR_SRC)/*.c) $(wildcard $(DIR_SRC)/*.cpp)

# All of the sources participating in the build are defined here,二次替换
OBJ		:= $(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(notdir ${SOURCE})))
OBJ		:=$(filter-out $(TARGET:%=%.o),$(OBJ))
OBJS    := $(addprefix $(DIR_OBJ)/,$(OBJ))
TARGET_OBJS :=$(TARGET:%=$(DIR_OBJ)/%.o)
#EXECOBJ = $(addprefix $(OBJDIR), $(EXECOBJA))
#DEPS	:=$(objects:.o=.d)  
DEPS	:= $(patsubst %.o,%.d,$(OBJS))
CFLAGS  := $(addprefix -D,$(DEFINES))  $(addprefix -I,$(DIR_INC)) -fPIC
FILE_MK	:= $(wildcard $(DIR_SRC)/*.mk)
ifneq ($(strip $(FILE_MK)),)
-include $(FILE_MK)
endif

ifeq ($(DEBUG), 0) 
	CFLAGS+= -O2 -g
else
	CFLAGS+= -O0 -g3 -Wall 
endif

CXXFLAGS:= $(CFLAGS)

#shell放入preinstall有问题，返回的数值会当作命令被执行
exist = $(shell if [ -d $(DIR_OBJ) ]; then echo "Directory $(DIR_OBJ) already exists,no need to create"; else mkdir -p $(DIR_OBJ); fi;)
preinstall:
	@echo $(exist)


all: $(TARGET)

$(TARGET) :exclude=$(filter-out $@,$(TARGET))
$(TARGET) :include=$(filter-out $(exclude:%=$(DIR_OBJ)/%.o),$(TARGET_OBJS))
$(TARGET) :$(TARGET_OBJS)
	@echo TARGET_OBJS=$(TARGET_OBJS)
	$(CC) $(include) $(LDFLAGS) -fPIC $(addprefix -L,$(DIR_LIB))  $(addprefix -L,$(DIR_OBJ)) -Wl,-Bstatic $(addprefix -l,$(LIBS_STATIC)) -Wl,-Bdynamic $(addprefix -l,$(LIBS))  -o $(DIR_OBJ)/$@  
#	$(CC) $(filter-out $(exclude:%=$(DIR_OBJ)/%.o),$(OBJS)) $(LDFLAGS) -fPIC $(addprefix -L,$(DIR_LIB))  $(addprefix -l,$(LIBS))   --verbose -o $(DIR_OBJ)/$@ 
#	$(CC) $(include) $(LDFLAGS) -fPIC $(addprefix -L,$(DIR_LIB)) -L $(DIR_OBJ) $(addprefix -l,$(LIBS)) -l $(TARGET_SO) -o $(DIR_OBJ)/$@ 
#	@$(DIR_OBJ)/$@    #编译后立即执行

#lib:include=$(filter-out $(TARGET),$(OBJ:%.o=%))
lib:preinstall $(OBJS)
	@echo OBJS=$(OBJS)
#	@echo $(include:%=$(DIR_OBJ)/%.o)										-Wl,-Bstatic $(addprefix -l,$(LIBS_STATIC)) -Wl,-Bdynamic
	$(CC) -fPIC -shared $(OBJS) $(LDFLAGS) $(addprefix -L,$(DIR_LIB)) -Wl,-Bstatic $(addprefix -l,$(LIBS_STATIC)) -Wl,-Bdynamic  $(addprefix -l,$(LIBS))  -o $(DIR_OBJ)/lib$(TARGET_SO).so 

clean:
	-rm -rf $(DIR_OBJ)/*
#	-rm -rf $(OBJS) $(DEPS) $(addprefix $(DIR_OBJ)/,$(TARGET)) $(addprefix $(DIR_OBJ)/lib,$(TARGET_SO:%=%.so))
#	-@echo ' '

.PHONY: all clean dependents preinstall

# Each subdirectory must supply rules for building sources it contributes

$(DIR_OBJ)/%.o: $(DIR_SRC)/%.cpp
#$(DIR_SRC)/%.o: $(DIR_SRC)/%.cpp
	@echo 'Building c++ file: $< $@'
	@echo 'Written by WanQing'
#	$(CC)  -c  -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	$(CC) $(opt) $(CXXFLAGS) -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

$(DIR_OBJ)/%.o: $(DIR_SRC)/%.c
	@echo 'Building c file: $< $@'
	@echo 'Written by WanQing'
#	$(CC)  -c  -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	$(CC) $(opt) $(CFLAGS) -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

# All Target $< $^ $(subst info,INFO,$@)
info info2: one.j two.j  
	@echo 'FILE_MK $(FILE_MK) $(TT) $(exist)'
	@echo $< $@

%.j:
	@echo 'test $@' 
cmodule:
	/root/data/lib/AndroidToolChain3/bin/aarch64-linux-android-gcc -fPIC -shared -DANDROID  -Wall -Os -pipe -O2 -g3 src/cmodule.c -o bin/libcmodule.so -L./lib -I./include -lfrida-gum -llog -ldl -lm
cmodule2:
	aarch64-linux-android-clang -fPIC  -DANDROID -ffunction-sections -fdata-sections -Wall -Os -pipe -O0 -g3 src/cmodule.c -o bin/cmodule -L./lib -I./include -lfrida-gum -llog -ldl -lm -fuse-ld=gold -Wl,--icf=all,--gc-sections,-z,relro,-z,now
cmodule_linux:
	gcc src/cmodule_linux.c -O0 -g -o bin/cmodule_linux
echo:   #调试时显示一些变量的值  
	@echo exclude=$(filter-out $(TARGET),$(OBJ:%.o=%))
	@echo SOURCE=$(SOURCE),INC=$(addprefix -I,$(DIR_INC))
	@echo OBJ=$(OBJ:%.o=%)
	@echo OBJS=$(OBJS)
 
#提醒：当混合编译.c/.cpp时，为了能够在C++程序里调用C函数，必须把每一个要调用的
#C函数，其声明都包括在extern "C"{}块里面，这样C++链接时才能成功链接它们。 
