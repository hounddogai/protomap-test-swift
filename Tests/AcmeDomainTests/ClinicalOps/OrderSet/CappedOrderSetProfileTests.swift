@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetProfileTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newCappedOrderSetProfile("code-541", title: "title-250")
        #expect(item.status == ClinicalOps.CappedOrderSetProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newCappedOrderSetProfile("code-541", title: "title-250")
        try item.moveTo(ClinicalOps.CappedOrderSetProfileStatus.validated)
        #expect(item.status == ClinicalOps.CappedOrderSetProfileStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newCappedOrderSetProfile("code-541", title: "title-250")
        item.status = ClinicalOps.CappedOrderSetProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedOrderSetProfileStatus.created) }
    }
}
