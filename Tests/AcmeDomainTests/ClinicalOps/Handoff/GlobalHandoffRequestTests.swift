@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalHandoffRequestTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newGlobalHandoffRequest("code-386", label: "label-654")
        #expect(item.status == ClinicalOps.GlobalHandoffRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newGlobalHandoffRequest("code-386", label: "label-654")
        try item.moveTo(ClinicalOps.GlobalHandoffRequestStatus.validated)
        #expect(item.status == ClinicalOps.GlobalHandoffRequestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newGlobalHandoffRequest("code-386", label: "label-654")
        item.status = ClinicalOps.GlobalHandoffRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalHandoffRequestStatus.created) }
    }
}
