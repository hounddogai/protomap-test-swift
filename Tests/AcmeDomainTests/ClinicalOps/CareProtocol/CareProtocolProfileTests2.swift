@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolProfileTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCareProtocolProfile("code-776", label: "label-782")
        #expect(item.status == ClinicalOps.CareProtocolProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = ClinicalOps.newCareProtocolProfile("code-776", label: "label-782")
        try item.moveTo(ClinicalOps.CareProtocolProfileStatus.inProgress)
        #expect(item.status == ClinicalOps.CareProtocolProfileStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCareProtocolProfile("code-776", label: "label-782")
        item.status = ClinicalOps.CareProtocolProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolProfileStatus.planned) }
    }
}
