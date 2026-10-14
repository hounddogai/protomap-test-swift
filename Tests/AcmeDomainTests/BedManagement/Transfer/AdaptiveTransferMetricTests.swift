@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveTransferMetricTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newAdaptiveTransferMetric("code-100", title: "title-930")
        #expect(item.status == BedManagement.AdaptiveTransferMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newAdaptiveTransferMetric("code-100", title: "title-930")
        try item.moveTo(BedManagement.AdaptiveTransferMetricStatus.expired)
        #expect(item.status == BedManagement.AdaptiveTransferMetricStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newAdaptiveTransferMetric("code-100", title: "title-930")
        item.status = BedManagement.AdaptiveTransferMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveTransferMetricStatus.requested) }
    }
}
