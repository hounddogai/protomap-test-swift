@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenMetricTests {
    @Test func startsInNew() throws {
        let item = Labs.newLegacySpecimenMetric("code-329", name: "name-358")
        #expect(item.status == Labs.LegacySpecimenMetricStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newLegacySpecimenMetric("code-329", name: "name-358")
        try item.moveTo(Labs.LegacySpecimenMetricStatus.running)
        #expect(item.status == Labs.LegacySpecimenMetricStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newLegacySpecimenMetric("code-329", name: "name-358")
        item.status = Labs.LegacySpecimenMetricStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacySpecimenMetricStatus.new) }
    }
}
