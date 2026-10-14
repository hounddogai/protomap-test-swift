@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationTierTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newPendingIsolationTier("code-344", label: "label-822")
        #expect(item.status == BedManagement.PendingIsolationTierStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = BedManagement.newPendingIsolationTier("code-344", label: "label-822")
        try item.moveTo(BedManagement.PendingIsolationTierStatus.inProgress)
        #expect(item.status == BedManagement.PendingIsolationTierStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newPendingIsolationTier("code-344", label: "label-822")
        item.status = BedManagement.PendingIsolationTierStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingIsolationTierStatus.planned) }
    }
}
