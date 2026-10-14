@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredCareProtocolClaimTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newTieredCareProtocolClaim("code-865", label: "label-345")
        #expect(item.status == ClinicalOps.TieredCareProtocolClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newTieredCareProtocolClaim("code-865", label: "label-345")
        try item.moveTo(ClinicalOps.TieredCareProtocolClaimStatus.warming)
        #expect(item.status == ClinicalOps.TieredCareProtocolClaimStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newTieredCareProtocolClaim("code-865", label: "label-345")
        item.status = ClinicalOps.TieredCareProtocolClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.TieredCareProtocolClaimStatus.idle) }
    }
}
