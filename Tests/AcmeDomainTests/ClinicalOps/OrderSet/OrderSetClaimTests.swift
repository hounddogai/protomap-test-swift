@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetClaimTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newOrderSetClaim("code-688", name: "name-261")
        #expect(item.status == ClinicalOps.OrderSetClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newOrderSetClaim("code-688", name: "name-261")
        try item.moveTo(ClinicalOps.OrderSetClaimStatus.cancelled)
        #expect(item.status == ClinicalOps.OrderSetClaimStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newOrderSetClaim("code-688", name: "name-261")
        item.status = ClinicalOps.OrderSetClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetClaimStatus.planned) }
    }
}
