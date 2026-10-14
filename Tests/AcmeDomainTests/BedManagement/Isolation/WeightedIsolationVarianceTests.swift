@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedIsolationVarianceTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newWeightedIsolationVariance("code-38", title: "title-595")
        #expect(item.status == BedManagement.WeightedIsolationVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newWeightedIsolationVariance("code-38", title: "title-595")
        try item.moveTo(BedManagement.WeightedIsolationVarianceStatus.queued)
        #expect(item.status == BedManagement.WeightedIsolationVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newWeightedIsolationVariance("code-38", title: "title-595")
        item.status = BedManagement.WeightedIsolationVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedIsolationVarianceStatus.new) }
    }
}
