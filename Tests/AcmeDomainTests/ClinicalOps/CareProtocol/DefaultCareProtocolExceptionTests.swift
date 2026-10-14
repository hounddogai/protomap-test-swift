@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolExceptionTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newDefaultCareProtocolException("code-337", title: "title-47")
        #expect(item.status == ClinicalOps.DefaultCareProtocolExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newDefaultCareProtocolException("code-337", title: "title-47")
        try item.moveTo(ClinicalOps.DefaultCareProtocolExceptionStatus.approved)
        #expect(item.status == ClinicalOps.DefaultCareProtocolExceptionStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newDefaultCareProtocolException("code-337", title: "title-47")
        item.status = ClinicalOps.DefaultCareProtocolExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultCareProtocolExceptionStatus.proposed) }
    }
}
