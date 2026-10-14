@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientCareProtocolPolicyTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newLenientCareProtocolPolicy("code-321", title: "title-615")
        #expect(item.status == ClinicalOps.LenientCareProtocolPolicyStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newLenientCareProtocolPolicy("code-321", title: "title-615")
        try item.moveTo(ClinicalOps.LenientCareProtocolPolicyStatus.granted)
        #expect(item.status == ClinicalOps.LenientCareProtocolPolicyStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newLenientCareProtocolPolicy("code-321", title: "title-615")
        item.status = ClinicalOps.LenientCareProtocolPolicyStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientCareProtocolPolicyStatus.requested) }
    }
}
