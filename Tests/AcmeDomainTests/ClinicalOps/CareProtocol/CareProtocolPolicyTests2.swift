@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolPolicyTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newCareProtocolPolicy("code-346", label: "label-200")
        #expect(item.status == ClinicalOps.CareProtocolPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = ClinicalOps.newCareProtocolPolicy("code-346", label: "label-200")
        try item.moveTo(ClinicalOps.CareProtocolPolicyStatus.cancelled)
        #expect(item.status == ClinicalOps.CareProtocolPolicyStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newCareProtocolPolicy("code-346", label: "label-200")
        item.status = ClinicalOps.CareProtocolPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolPolicyStatus.planned) }
    }
}
