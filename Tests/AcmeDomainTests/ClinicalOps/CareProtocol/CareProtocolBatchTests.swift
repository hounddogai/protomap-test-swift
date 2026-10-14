@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolBatchTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newCareProtocolBatch("code-504", name: "name-691")
        #expect(item.status == ClinicalOps.CareProtocolBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newCareProtocolBatch("code-504", name: "name-691")
        try item.moveTo(ClinicalOps.CareProtocolBatchStatus.published)
        #expect(item.status == ClinicalOps.CareProtocolBatchStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newCareProtocolBatch("code-504", name: "name-691")
        item.status = ClinicalOps.CareProtocolBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolBatchStatus.created) }
    }
}
