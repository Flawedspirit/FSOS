org 0x7c00                              ;Memory address all bootloaders need to start at
bits 16                                 ;We in 16-bit real mode, son!

%define ENDL 0x0d, 0x0a

; FAT12 HEADER
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'               ;8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0xe0
bdb_total_sectors:          dw 2880                     ;2880 * 512 = 1.44 MB
bdb_media_desc_type:        db 0xf0                     ;F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sector_count:    dd 0
bdb_large_sector_count:     dd 0

; Extended boot record
ebr_drive_number:           db 0
                            db 0                        ;Reserved byte (should be zero)
ebr_signature:              db 0x29
ebr_volume_id:              db 0x46, 0x55, 0x43, 0x4b   ;Value doesn't matter
ebr_volume_label:           db 'SHITTY_OS  '            ;11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '               ;8 bytes, padded with spaces

; END FAT12 HEADER

start:
    jmp init                            ;Perform initialization of memory spaces

puts:
    push si
    push ax
    push bx

.str_loop:
    lodsb                               ;Load next character in al
    or al, al                           ;Checks if next character is null
    jz .done

    mov ah, 0x0e                        ;Signal BIOS to begin outputting characters in TTY mode
    mov bh, 0
    int 0x10                            ;BIOS video interrupt, aka print the character
    jmp .str_loop

.done:
    pop bx
    pop ax
    pop si
    ret

init:
    xor ax, ax                          ;Clear AX register
    mov ss, ax                          ;Clear registers by setting them to ax
    mov ds, ax
    mov es, ax

    mov sp, start                       ;Start our stack at the lowest memory address
    cld                                 ;Make sure execution starts from lowest address

    ; Read something from the disk
    mov [ebr_drive_number], dl          ;The BIOS should set dl to the drive number it's reading from

    mov ax, 1                           ;Begin in second sector
    mov cl, 1                           ;Read 1 sector
    mov bx, 0x7e00                      ;Data should be after bootloader
    call read_disk

    mov si, msg_booting
    call puts

    cli
    jmp $

floppy_error:
    mov si, msg_read_fail
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 0x16                            ;Wait for a key press
    jmp 0xffff:0                        ;Jump to beginning of BIOS, should reboot

.halt:
    cli                                 ;Disable interrupts so CPU can't escape halt state
    jmp $

; TRANSLATE LBA TO CHS
; Params:
;   ax: LBA address
; Returns:
;   cx [0-5]: sector
;   cx [6-15]: cylinder
;   dh: head
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ;Clear dx
    div word [bdb_sectors_per_track]    ;ax = LBA / sectors_per_track
                                        ;dx = LBA % sectors_per_track
    inc dx                              ;dx = (LBA % sectors_per_track + 1) = sector
    mov cx, dx                          ;cx = sector

    xor dx, dx
    div word [bdb_heads]                ;ax = (LBA / sectors_per_track) / heads = cylinder
                                        ;dx = (LBA / sectors_per_track) % heads = head
    mov dh, dl                          ;dh = head
    mov ch, al                          ;ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ;Put upper 2 bits of cylnder in cl

    pop ax
    mov dl, al                          ;Restore dl
    pop ax
    ret

; READ SECTORS FROM DISK
; Params:
;   ax: LBA address
;   cl: number of sectors to read (up to 128)
;   dl: drive number
;   es:bx: memory address to store read data
read_disk:
    push ax                             ;Save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ;Temporarily save cl
    call lba_to_chs                     ;Get physical location from our provided address
    pop ax                              ;al = number of sectors to read

    mov ah, 0x02
    mov di, 3                           ;Retry count to compensate for floppy drive unreliability

.retry:
    pusha                               ;We don't know what registers BIOS will modify, so save them all
    stc                                 ;Set carry flag because some BIOSes don't do it for you
    int 0x13                            ;Carry flag clears on success
    jnc .done

    popa                                ;If the operation fails
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop di                             ;Restore registers we modified
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; RESET DISK
; Params:
;       dl: Drive number
disk_reset:
    pusha
    mov ah, 0
    stc
    int 0x13
    jc floppy_error
    popa
    ret

msg_booting: db "Booting The World's Shittiest OS...", ENDL, 0
msg_read_fail: db "Could not boot from disk.", ENDL, 0

times 510-($-$$) db 0                   ;Padding to make the file 512 bytes minus magic number
dw 0xaa55                               ;Magic number - the reason for the season