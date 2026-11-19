import Foundation
import TestFlows

enum AppleNumbersFlowSuite:
    TestFlowRegistry
{
    static let title = "AppleNumbers flow tests"

    static var flows: [TestFlow] {
        var result: [TestFlow] = [
            numbersSchemaInferenceFlow,
            numbersIWAFoundationFlow,
            numbersNativeTileStorageFlow,
            numbersNativeSnapshotFlow,
            numbersNativeFormatMatrixFlow,
            numbersNativeBNCFormatSelectionFlow,
            numbersNativeRowPlacementFlow,
            numbersNativeWideOffsetFlow,
            numbersNativeComprehensiveSnapshotFlow,
        ]

        if let python =
            ProcessInfo.processInfo
                .environment[
                    "APPLE_NUMBERS_ORACLE_PYTHON"
                ],
            !python.isEmpty
        {
            result.append(
                numbersDirectPackageOracleFlow
            )
        }

        return result
    }
}
