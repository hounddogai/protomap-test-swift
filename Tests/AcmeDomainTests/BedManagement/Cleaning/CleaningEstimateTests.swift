@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningEstimateTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCleaningEstimate("code-667", name: "name-36")
        #expect(item.status == BedManagement.CleaningEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newCleaningEstimate("code-667", name: "name-36")
        try item.moveTo(BedManagement.CleaningEstimateStatus.queued)
        #expect(item.status == BedManagement.CleaningEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCleaningEstimate("code-667", name: "name-36")
        item.status = BedManagement.CleaningEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningEstimateStatus.new) }
    }
}
