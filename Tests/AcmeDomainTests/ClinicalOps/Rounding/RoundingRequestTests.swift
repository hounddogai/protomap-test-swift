@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingRequestTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newRoundingRequest("code-320", label: "label-447")
        #expect(item.status == ClinicalOps.RoundingRequestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newRoundingRequest("code-320", label: "label-447")
        try item.moveTo(ClinicalOps.RoundingRequestStatus.validated)
        #expect(item.status == ClinicalOps.RoundingRequestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newRoundingRequest("code-320", label: "label-447")
        item.status = ClinicalOps.RoundingRequestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingRequestStatus.created) }
    }
}
