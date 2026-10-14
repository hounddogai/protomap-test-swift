@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanMetricTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newDischargePlanMetric("code-99", title: "title-990")
        #expect(item.status == BedManagement.DischargePlanMetricStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newDischargePlanMetric("code-99", title: "title-990")
        try item.moveTo(BedManagement.DischargePlanMetricStatus.published)
        #expect(item.status == BedManagement.DischargePlanMetricStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newDischargePlanMetric("code-99", title: "title-990")
        item.status = BedManagement.DischargePlanMetricStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanMetricStatus.created) }
    }
}
