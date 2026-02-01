package utils

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:sys/posix"
//void randname(char* buf)
//{
//    struct timespec ts;
//    clock_gettime(CLOCK_REALTIME, &ts);
//    long r = ts.tv_nsec;
//    for (int i = 0; i < 6; ++i) {
//        buf[i] = 'A' + (r & 15) + (r & 16) * 2;
//        r >>= 5;
//    }
//}
//
//int create_shm_file(void)
//{
//    int retries = 100;
//    do {
//        char name[] = "/wl_shm-XXXXXX";
//        randname(name + sizeof(name) - 7);
//        --retries;
//        int fd = shm_open(name, O_RDWR | O_CREAT | O_EXCL, 0600);
//        if (fd >= 0) {
//            shm_unlink(name);
//            return fd;
//        }
//    } while (retries > 0 && errno == EEXIST);
//    return -1;
//}
//
//int allocate_shm_file(size_t size)
//{
//    int fd = create_shm_file();
//    if (fd < 0)
//        return -1;
//    int ret;
//    do {
//        ret = ftruncate(fd, size);
//    } while (ret < 0 && errno == EINTR);
//    if (ret < 0) {
//        close(fd);
//        return -1;
//    }
//    return fd;
//}


// Dumb I know
_choices: []u8 = {
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
	'g',
	'h',
	'i',
	'j',
	'k',
	'l',
	'm',
	'n',
	'o',
	'p',
	'q',
	'r',
	's',
	't',
	'u',
	'v',
	'w',
	'x',
	'y',
	'z',
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z',
}
rand_string :: proc(size: uint) -> string {
	sb := strings.builder_make()

	for i in 0 ..< size {
		strings.write_byte(&sb, rand.choice(_choices[:]))
	}

	return strings.to_string(sb)
}

create_shm_file :: proc() -> posix.FD {
	using posix
	for _ in 1 ..= 100 {
		name := strings.clone_to_cstring(fmt.tprintf("/wl-shm-%s", rand_string(16)))
		fd := shm_open(
			name,
			{O_Flag_Bits.RDWR, O_Flag_Bits.CREAT, O_Flag_Bits.EXCL},
			{Mode_Bits.IWUSR, Mode_Bits.IRUSR},
		)
		if (fd >= 0) {
			posix.shm_unlink(name)
			return fd
		}
		if get_errno() != Errno.EEXIST {
			break
		}
	}
	return -1
}

allocate_shm_file :: proc(size: uint) -> posix.FD {
	using posix
	fd := create_shm_file()
	if (fd < 0) {
		return -1
	}

	ret := posix.result.OK
	err := get_errno()
	for {
		ret = ftruncate(fd, posix.off_t(size))
		err = get_errno()
		if ret == result.OK || err != Errno.EINTR {
			break
		}
	}
	if (ret != result.OK) {
		close(fd)
		return -1
	}

	return fd
}
