@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffQuotaTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newHandoffQuota("code-598", name: "name-814")
        #expect(item.status == ClinicalOps.HandoffQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newHandoffQuota("code-598", name: "name-814")
        try item.moveTo(ClinicalOps.HandoffQuotaStatus.validated)
        #expect(item.status == ClinicalOps.HandoffQuotaStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newHandoffQuota("code-598", name: "name-814")
        item.status = ClinicalOps.HandoffQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffQuotaStatus.created) }
    }
}
