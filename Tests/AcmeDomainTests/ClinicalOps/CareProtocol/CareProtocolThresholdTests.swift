@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolThresholdTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCareProtocolThreshold("code-633", title: "title-816")
        #expect(item.status == ClinicalOps.CareProtocolThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newCareProtocolThreshold("code-633", title: "title-816")
        try item.moveTo(ClinicalOps.CareProtocolThresholdStatus.resolved)
        #expect(item.status == ClinicalOps.CareProtocolThresholdStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCareProtocolThreshold("code-633", title: "title-816")
        item.status = ClinicalOps.CareProtocolThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolThresholdStatus.`open`) }
    }
}
