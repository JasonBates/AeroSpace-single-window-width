public struct FocusModeCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .focusMode,
        help: focus_mode_help_generated,
        flags: [:],
        posArgs: [],
    )
}
