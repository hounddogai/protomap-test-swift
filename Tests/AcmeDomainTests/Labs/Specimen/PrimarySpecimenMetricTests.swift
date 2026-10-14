@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimarySpecimenMetricTests {
    @Test func startsInRequested() throws {
        let item = Labs.newPrimarySpecimenMetric("code-729", label: "label-485")
        #expect(item.status == Labs.PrimarySpecimenMetricStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Labs.newPrimarySpecimenMetric("code-729", label: "label-485")
        try item.moveTo(Labs.PrimarySpecimenMetricStatus.expired)
        #expect(item.status == Labs.PrimarySpecimenMetricStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newPrimarySpecimenMetric("code-729", label: "label-485")
        item.status = Labs.PrimarySpecimenMetricStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PrimarySpecimenMetricStatus.requested) }
    }
}
