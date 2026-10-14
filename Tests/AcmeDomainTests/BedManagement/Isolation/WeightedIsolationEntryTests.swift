@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationEntryTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newWeightedIsolationEntry("code-139", label: "label-349")
        #expect(item.status == BedManagement.WeightedIsolationEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newWeightedIsolationEntry("code-139", label: "label-349")
        try item.moveTo(BedManagement.WeightedIsolationEntryStatus.suspended)
        #expect(item.status == BedManagement.WeightedIsolationEntryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newWeightedIsolationEntry("code-139", label: "label-349")
        item.status = BedManagement.WeightedIsolationEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedIsolationEntryStatus.draft) }
    }
}
