@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedCleaningMetricTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newWeightedCleaningMetric("code-981", name: "name-656")
        #expect(item.status == BedManagement.WeightedCleaningMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newWeightedCleaningMetric("code-981", name: "name-656")
        try item.moveTo(BedManagement.WeightedCleaningMetricStatus.revoked)
        #expect(item.status == BedManagement.WeightedCleaningMetricStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newWeightedCleaningMetric("code-981", name: "name-656")
        item.status = BedManagement.WeightedCleaningMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedCleaningMetricStatus.requested) }
    }
}
