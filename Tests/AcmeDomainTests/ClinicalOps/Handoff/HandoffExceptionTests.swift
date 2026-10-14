@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffExceptionTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newHandoffException("code-22", title: "title-340")
        #expect(item.status == ClinicalOps.HandoffExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newHandoffException("code-22", title: "title-340")
        try item.moveTo(ClinicalOps.HandoffExceptionStatus.validated)
        #expect(item.status == ClinicalOps.HandoffExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newHandoffException("code-22", title: "title-340")
        item.status = ClinicalOps.HandoffExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffExceptionStatus.created) }
    }
}
