const std = @import("std");

pub const Register = enum(u5) {
    ax = 0b000,
    cx = 0b001,
    dx = 0b010,
    bx = 0b011,
    sp = 0b100,
    bp = 0b101,
    si = 0b110,
    di = 0b111,

    al = 0b1000,
    cl = 0b1001,
    dl = 0b1010,
    bl = 0b1011,

    ah = 0b11000,
    ch = 0b11001,
    dh = 0b11010,
    bh = 0b11011,

    pub fn toIndex(self: Register) u3 {
        return @truncate(@intFromEnum(self) & 0b111);
    }

    pub fn toString(self: Register) []const u8 {
        return switch (self) {
            .ax => "ax",
            .cx => "cx",
            .dx => "dx",
            .bx => "bx",
            .sp => "sp",
            .bp => "bp",
            .si => "si",
            .di => "di",
            .al => "al",
            .cl => "cl",
            .dl => "dl",
            .bl => "bl",
            .ah => "ah",
            .ch => "ch",
            .dh => "dh",
            .bh => "bh",
        };
    }
};

pub const MemAddressExpression = struct {
    reg1: ?Register = null,
    reg2: ?Register = null,
    disp: ?u16 = null,
};

pub const Op = enum {
    mov,
    add,
    sub,
    cmp,

    pub fn toString(self: Op) []const u8 {
        return switch (self) {
            .mov => "mov",
            .add => "add",
            .sub => "sub",
            .cmp => "cmp",
        };
    }
};

pub const RegToReg = struct {
    op: Op,
    src: Register,
    dst: Register,
};

pub const RegToMem = struct {
    op: Op,
    src: Register,
    dst: MemAddressExpression,
};

pub const MemToReg = struct {
    op: Op,
    src: MemAddressExpression,
    dst: Register,
};

pub const ImmToReg = struct {
    op: Op,
    imm: u16,
    dst: Register,
};

pub const ImmToMem = struct {
    op: Op,
    word: bool,
    imm: u16,
    dst: MemAddressExpression,
};

pub const JumpEnum = enum {
    je,
    jl,
    jle,
    jb,
    jbe,
    jp,
    jo,
    js,
    jne,
    jnl,
    jg,
    jnb,
    ja,
    jnp,
    jno,
    jns,
    loop,
    loopz,
    loopnz,
    jcxz,

    fn toString(self: JumpEnum) []const u8 {
        return switch (self) {
            .je => "je",
            .jl => "jl",
            .jle => "jle",
            .jb => "jb",
            .jbe => "jbe",
            .jp => "jp",
            .jo => "jo",
            .js => "js",
            .jne => "jne",
            .jnl => "jnl",
            .jg => "jg",
            .jnb => "jnb",
            .ja => "ja",
            .jnp => "jnp",
            .jno => "jno",
            .jns => "jns",
            .loop => "loop",
            .loopz => "loopz",
            .loopnz => "loopnz",
            .jcxz => "jcxz",
        };
    }
};

pub const Jump = struct {
    jump: JumpEnum,
    ip_inc8: i8,
};

pub const Instruction = union(enum) {
    reg_to_reg: RegToReg,
    reg_to_mem: RegToMem,
    mem_to_reg: MemToReg,
    imm_to_reg: ImmToReg,
    imm_to_mem: ImmToMem,
    jump: Jump,

    pub fn print(self: Instruction, scratchpad: []u8) !u5 {
        var tmp: []u8 = undefined;
        switch (self) {
            .reg_to_reg => |ins| {
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, {s}\n", .{
                    ins.op.toString(),
                    ins.dst.toString(),
                    ins.src.toString(),
                });
            },
            .reg_to_mem => |ins| {
                if (ins.dst.reg1 == null) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} [{d}], {s}\n", .{
                        ins.op.toString(),
                        ins.dst.disp.?,
                        ins.src.toString(),
                    });
                } else if (ins.dst.disp == null) {
                    if (ins.dst.reg2 == null) {
                        tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s}], {s}\n", .{
                            ins.op.toString(),
                            ins.dst.reg1.?.toString(),
                            ins.src.toString(),
                        });
                    } else {
                        tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s} + {s}], {s}\n", .{
                            ins.op.toString(),
                            ins.dst.reg1.?.toString(),
                            ins.dst.reg2.?.toString(),
                            ins.src.toString(),
                        });
                    }
                } else if (ins.dst.reg2 == null) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s} + {d}], {s}\n", .{
                        ins.op.toString(),
                        ins.dst.reg1.?.toString(),
                        ins.dst.disp.?,
                        ins.src.toString(),
                    });
                } else {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s} + {s} + {d}], {s}\n", .{
                        ins.op.toString(),
                        ins.dst.reg1.?.toString(),
                        ins.dst.reg2.?.toString(),
                        ins.dst.disp.?,
                        ins.src.toString(),
                    });
                }
            },
            .mem_to_reg => |ins| {
                if (ins.src.reg1 == null) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{d}]\n", .{
                        ins.op.toString(),
                        ins.dst.toString(),
                        ins.src.disp.?,
                    });
                } else if (ins.src.disp == null) {
                    if (ins.src.reg2 == null) {
                        tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s}]\n", .{
                            ins.op.toString(),
                            ins.dst.toString(),
                            ins.src.reg1.?.toString(),
                        });
                    } else {
                        tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s} + {s}]\n", .{
                            ins.op.toString(),
                            ins.dst.toString(),
                            ins.src.reg1.?.toString(),
                            ins.src.reg2.?.toString(),
                        });
                    }
                } else if (ins.src.reg2 == null) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s} + {d}]\n", .{
                        ins.op.toString(),
                        ins.dst.toString(),
                        ins.src.reg1.?.toString(),
                        ins.src.disp.?,
                    });
                } else {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s} + {s} + {d}]\n", .{
                        ins.op.toString(),
                        ins.dst.toString(),
                        ins.src.reg1.?.toString(),
                        ins.src.reg2.?.toString(),
                        ins.src.disp.?,
                    });
                }
            },
            .imm_to_reg => |ins| {
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, {d}\n", .{
                    ins.op.toString(),
                    ins.dst.toString(),
                    ins.imm,
                });
            },
            .imm_to_mem => |ins| {
                const byte_or_word = if (ins.word) "word" else "byte";
                if (ins.dst.reg1 == null) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{d}] {d}\n", .{
                        ins.op.toString(),
                        byte_or_word,
                        ins.dst.disp.?,
                        ins.imm,
                    });
                } else if (ins.dst.disp == null) {
                    if (ins.dst.reg2 == null) {
                        tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s}], {d}\n", .{
                            ins.op.toString(),
                            byte_or_word,
                            ins.dst.reg1.?.toString(),
                            ins.imm,
                        });
                    } else {
                        tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s} + {s}], {d}\n", .{
                            ins.op.toString(),
                            byte_or_word,
                            ins.dst.reg1.?.toString(),
                            ins.dst.reg2.?.toString(),
                            ins.imm,
                        });
                    }
                } else if (ins.dst.reg2 == null) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s} + {d}], {d}\n", .{
                        ins.op.toString(),
                        byte_or_word,
                        ins.dst.reg1.?.toString(),
                        ins.dst.disp.?,
                        ins.imm,
                    });
                } else {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s} + {s} + {d}], {d}\n", .{
                        ins.op.toString(),
                        byte_or_word,
                        ins.dst.reg1.?.toString(),
                        ins.dst.reg2.?.toString(),
                        ins.dst.disp.?,
                        ins.imm,
                    });
                }
            },
            .jump => |ins| {
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {d}\n", .{ ins.jump.toString(), ins.ip_inc8 });
            },
        }
        return @truncate(tmp.len);
    }
};
