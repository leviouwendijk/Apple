import TestFlows

@main
enum AppleNumbersTestFlowsMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: AppleNumbersFlowSuite.self
        )
    }
}
