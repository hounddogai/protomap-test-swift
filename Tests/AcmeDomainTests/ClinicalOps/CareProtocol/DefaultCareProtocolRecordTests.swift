@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultCareProtocolRecordTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newDefaultCareProtocolRecord("code-947", title: "title-342")
        #expect(item.status == ClinicalOps.DefaultCareProtocolRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newDefaultCareProtocolRecord("code-947", title: "title-342")
        try item.moveTo(ClinicalOps.DefaultCareProtocolRecordStatus.approved)
        #expect(item.status == ClinicalOps.DefaultCareProtocolRecordStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newDefaultCareProtocolRecord("code-947", title: "title-342")
        item.status = ClinicalOps.DefaultCareProtocolRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.DefaultCareProtocolRecordStatus.proposed) }
    }
}
