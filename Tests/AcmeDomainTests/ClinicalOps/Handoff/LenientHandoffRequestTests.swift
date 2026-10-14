@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientHandoffRequestTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newLenientHandoffRequest("code-242", label: "label-281")
        #expect(item.status == ClinicalOps.LenientHandoffRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newLenientHandoffRequest("code-242", label: "label-281")
        try item.moveTo(ClinicalOps.LenientHandoffRequestStatus.retired)
        #expect(item.status == ClinicalOps.LenientHandoffRequestStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newLenientHandoffRequest("code-242", label: "label-281")
        item.status = ClinicalOps.LenientHandoffRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LenientHandoffRequestStatus.created) }
    }
}
