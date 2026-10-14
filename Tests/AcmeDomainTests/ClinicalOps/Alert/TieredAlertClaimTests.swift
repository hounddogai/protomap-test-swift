@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredAlertClaimTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newTieredAlertClaim("code-581", title: "title-901")
        #expect(item.status == ClinicalOps.TieredAlertClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newTieredAlertClaim("code-581", title: "title-901")
        try item.moveTo(ClinicalOps.TieredAlertClaimStatus.failed)
        #expect(item.status == ClinicalOps.TieredAlertClaimStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newTieredAlertClaim("code-581", title: "title-901")
        item.status = ClinicalOps.TieredAlertClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredAlertClaimStatus.new) }
    }
}
