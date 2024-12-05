	section .text
	global draw_pad, draw_ball
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow
    extern XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent
    extern XStoreName, XCreateGC, XDrawRectangle, XFillRectangle, XFlush
	extern XDefaultGC, XSetForeground, XSetBackground, XDefaultScreen, XSelectInput
	extern XPending, XClearWindow, draw_pad
init_window:
	push rbp
	mov rbp, rsp


    mov rsp, rbp
	pop rbp
	ret
	
