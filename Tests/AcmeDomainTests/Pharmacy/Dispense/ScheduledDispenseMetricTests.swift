@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledDispenseMetricTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newScheduledDispenseMetric("code-60", name: "name-48")
        #expect(item.status == Pharmacy.ScheduledDispenseMetricStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newScheduledDispenseMetric("code-60", name: "name-48")
        try item.moveTo(Pharmacy.ScheduledDispenseMetricStatus.published)
        #expect(item.status == Pharmacy.ScheduledDispenseMetricStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newScheduledDispenseMetric("code-60", name: "name-48")
        item.status = Pharmacy.ScheduledDispenseMetricStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledDispenseMetricStatus.created) }
    }
}
