@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardRollupTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newManualBedBoardRollup("code-406", label: "label-869")
        #expect(item.status == BedManagement.ManualBedBoardRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newManualBedBoardRollup("code-406", label: "label-869")
        try item.moveTo(BedManagement.ManualBedBoardRollupStatus.warming)
        #expect(item.status == BedManagement.ManualBedBoardRollupStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newManualBedBoardRollup("code-406", label: "label-869")
        item.status = BedManagement.ManualBedBoardRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualBedBoardRollupStatus.idle) }
    }
}
