import Foundation

enum NumbersSnapshotExtraction {
    static func extract(
        at documentURL: URL
    ) throws -> Data {
        try NumbersScriptRunner.runJavaScript(
            NumbersSnapshotScript.source,
            arguments: [
                documentURL.path,
            ]
        )
    }
}
