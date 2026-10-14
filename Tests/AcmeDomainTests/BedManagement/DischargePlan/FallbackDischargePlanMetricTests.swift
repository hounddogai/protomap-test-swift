@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanMetricTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newFallbackDischargePlanMetric("code-87", label: "label-580")
        #expect(item.status == BedManagement.FallbackDischargePlanMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newFallbackDischargePlanMetric("code-87", label: "label-580")
        try item.moveTo(BedManagement.FallbackDischargePlanMetricStatus.rejected)
        #expect(item.status == BedManagement.FallbackDischargePlanMetricStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newFallbackDischargePlanMetric("code-87", label: "label-580")
        item.status = BedManagement.FallbackDischargePlanMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackDischargePlanMetricStatus.proposed) }
    }
}
