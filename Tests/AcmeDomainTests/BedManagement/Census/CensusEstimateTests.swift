@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusEstimateTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCensusEstimate("code-256", label: "label-780")
        #expect(item.status == BedManagement.CensusEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newCensusEstimate("code-256", label: "label-780")
        try item.moveTo(BedManagement.CensusEstimateStatus.queued)
        #expect(item.status == BedManagement.CensusEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCensusEstimate("code-256", label: "label-780")
        item.status = BedManagement.CensusEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CensusEstimateStatus.new) }
    }
}
