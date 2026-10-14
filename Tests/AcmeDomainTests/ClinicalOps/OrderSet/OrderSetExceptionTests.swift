@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetExceptionTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newOrderSetException("code-349", title: "title-456")
        #expect(item.status == ClinicalOps.OrderSetExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newOrderSetException("code-349", title: "title-456")
        try item.moveTo(ClinicalOps.OrderSetExceptionStatus.validated)
        #expect(item.status == ClinicalOps.OrderSetExceptionStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newOrderSetException("code-349", title: "title-456")
        item.status = ClinicalOps.OrderSetExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetExceptionStatus.created) }
    }
}
