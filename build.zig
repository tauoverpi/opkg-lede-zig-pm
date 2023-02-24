const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libubox = b.dependency("libubox", .{
        .target = target,
        .optimize = optimize,
    });

    const host_cpu = b.option([]const u8, "HOST_CPU", "override host cpu") orelse "x86_64-linux-musl";
    const build_cpu = b.option([]const u8, "BUILD_CPU", "override host cpu") orelse "x86_64-linux-musl";
    const lock_file = b.option([]const u8, "LOCK_FILE", "override lock file path") orelse "/var/lock/opkg.lock";
    const path_spec = b.option([]const u8, "PATH_SPEC", "override default path value") orelse "/usr/sbin:/usr/bin:/sbin:/bin";
    const version = b.option([]const u8, "VERSION", "Override version") orelse "0.0.0";

    const flags = &.{
        "-Os",
        "-Wall",
        "--std=gnu99",
        "-g3",
        "-Wmissing-declarations",
        "-DDATADIR=\"/usr/share\"",
        "-DOPKGETCDIR=\"/etc\"",
        b.fmt("-DOPKGLOCKFILE=\"{s}\"", .{lock_file}),
        "-DOPKGLIBDIR=\"/usr/lib\"",
        b.fmt("-DHOST_CPU_STR=\"{s}\"", .{host_cpu}),
        b.fmt("-DBUILD_CPU=\"{s}\"", .{build_cpu}),
        b.fmt("-DPATH_SPEC=\"{s}\"", .{path_spec}),
        b.fmt("-DVERSION=\"{s}\"", .{version}),
    };

    const libbb = b.addStaticLibrary(.{
        .name = "libbb",
        .target = target,
        .optimize = optimize,
    });

    libbb.linkLibC();
    libbb.addCSourceFiles(libbb_src, flags);
    libbb.installHeadersDirectoryOptions(.{
        .source_dir = "libbb",
        .install_dir = .header,
        .install_subdir = "libbb",
        .exclude_extensions = &.{".c", ".txt" },
    });

    const libopkg = b.addStaticLibrary(.{
        .name = "libopkg",
        .target = target,
        .optimize = optimize,
    });

    libopkg.linkLibC();
    libopkg.linkLibrary(libbb);
    libopkg.linkLibrary(libubox.artifact("libubox"));
    libopkg.addCSourceFiles(libopkg_src, flags);
    libopkg.installHeadersDirectoryOptions(.{
        .source_dir = "libopkg",
        .install_dir = .header,
        .install_subdir = "libopkg",
        .exclude_extensions = &.{".c", ".txt" },
    });

    const exe = b.addExecutable(.{
        .name = "opkg",
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkLibrary(libopkg);
    exe.linkLibrary(libubox.artifact("libubox"));
    exe.addIncludePath("libopkg");
    exe.addCSourceFiles(opkg_src, flags);
    exe.install();
}

const opkg_src = &.{
    "src/opkg-cl.c",
};

const libopkg_src = &.{
    "libopkg/active_list.c",
    "libopkg/conffile.c",
    "libopkg/conffile_list.c",
    "libopkg/file_util.c",
    "libopkg/hash_table.c",
    "libopkg/nv_pair.c",
    "libopkg/nv_pair_list.c",
    "libopkg/opkg.c",
    "libopkg/opkg_cmd.c",
    "libopkg/opkg_conf.c",
    "libopkg/opkg_configure.c",
    "libopkg/opkg_download.c",
    "libopkg/opkg_install.c",
    "libopkg/opkg_message.c",
    "libopkg/opkg_remove.c",
    "libopkg/opkg_upgrade.c",
    "libopkg/opkg_utils.c",
    "libopkg/parse_util.c",
    "libopkg/pkg.c",
    "libopkg/pkg_alternatives.c",
    "libopkg/pkg_depends.c",
    "libopkg/pkg_dest.c",
    "libopkg/pkg_dest_list.c",
    "libopkg/pkg_extract.c",
    "libopkg/pkg_hash.c",
    "libopkg/pkg_parse.c",
    "libopkg/pkg_src.c",
    "libopkg/pkg_src_list.c",
    "libopkg/pkg_vec.c",
    "libopkg/sha256.c",
    "libopkg/sprintf_alloc.c",
    "libopkg/str_list.c",
    "libopkg/void_list.c",
    "libopkg/xregex.c",
    "libopkg/xsystem.c",
};

const libbb_src = &.{
    "libbb/all_read.c",
    "libbb/concat_path_file.c",
    "libbb/copy_file.c",
    "libbb/copy_file_chunk.c",
    "libbb/gz_open.c",
    "libbb/gzip.c",
    "libbb/last_char_is.c",
    "libbb/make_directory.c",
    "libbb/mode_string.c",
    "libbb/parse_mode.c",
    "libbb/safe_strncpy.c",
    "libbb/time_string.c",
    "libbb/unarchive.c",
    "libbb/unzip.c",
    "libbb/wfopen.c",
    "libbb/xfuncs.c",
    "libbb/xreadlink.c",
};
