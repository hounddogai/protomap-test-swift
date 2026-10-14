@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallMetricTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newManualRecallMetric("code-719", label: "label-858")
        #expect(item.status == Pharmacy.ManualRecallMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newManualRecallMetric("code-719", label: "label-858")
        try item.moveTo(Pharmacy.ManualRecallMetricStatus.reopened)
        #expect(item.status == Pharmacy.ManualRecallMetricStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newManualRecallMetric("code-719", label: "label-858")
        item.status = Pharmacy.ManualRecallMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallMetricStatus.`open`) }
    }
}
