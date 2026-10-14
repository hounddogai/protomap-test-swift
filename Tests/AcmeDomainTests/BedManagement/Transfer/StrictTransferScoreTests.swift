@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictTransferScoreTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newStrictTransferScore("code-604", label: "label-553")
        #expect(item.status == BedManagement.StrictTransferScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newStrictTransferScore("code-604", label: "label-553")
        try item.moveTo(BedManagement.StrictTransferScoreStatus.granted)
        #expect(item.status == BedManagement.StrictTransferScoreStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newStrictTransferScore("code-604", label: "label-553")
        item.status = BedManagement.StrictTransferScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictTransferScoreStatus.requested) }
    }
}
