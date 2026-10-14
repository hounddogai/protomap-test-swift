@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingExceptionTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newRoundingException("code-827", name: "name-204")
        #expect(item.status == ClinicalOps.RoundingExceptionStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newRoundingException("code-827", name: "name-204")
        try item.moveTo(ClinicalOps.RoundingExceptionStatus.scheduled)
        #expect(item.status == ClinicalOps.RoundingExceptionStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newRoundingException("code-827", name: "name-204")
        item.status = ClinicalOps.RoundingExceptionStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingExceptionStatus.planned) }
    }
}
