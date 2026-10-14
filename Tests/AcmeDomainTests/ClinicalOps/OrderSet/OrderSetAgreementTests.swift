@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetAgreementTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newOrderSetAgreement("code-614", title: "title-766")
        #expect(item.status == ClinicalOps.OrderSetAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = ClinicalOps.newOrderSetAgreement("code-614", title: "title-766")
        try item.moveTo(ClinicalOps.OrderSetAgreementStatus.done)
        #expect(item.status == ClinicalOps.OrderSetAgreementStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newOrderSetAgreement("code-614", title: "title-766")
        item.status = ClinicalOps.OrderSetAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetAgreementStatus.new) }
    }
}
