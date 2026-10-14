@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMetricTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCareProtocolMetric("code-542", name: "name-831")
        #expect(item.status == ClinicalOps.CareProtocolMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = ClinicalOps.newCareProtocolMetric("code-542", name: "name-831")
        try item.moveTo(ClinicalOps.CareProtocolMetricStatus.archived)
        #expect(item.status == ClinicalOps.CareProtocolMetricStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCareProtocolMetric("code-542", name: "name-831")
        item.status = ClinicalOps.CareProtocolMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolMetricStatus.`open`) }
    }
}
