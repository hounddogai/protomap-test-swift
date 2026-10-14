@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRollupTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningRollup("code-612", label: "label-325")
        #expect(item.status == BedManagement.CleaningRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newCleaningRollup("code-612", label: "label-325")
        try item.moveTo(BedManagement.CleaningRollupStatus.queued)
        #expect(item.status == BedManagement.CleaningRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningRollup("code-612", label: "label-325")
        item.status = BedManagement.CleaningRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningRollupStatus.new) }
    }
}
