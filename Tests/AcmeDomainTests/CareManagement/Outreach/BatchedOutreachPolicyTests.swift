@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachPolicyTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newBatchedOutreachPolicy("code-298", name: "name-449")
        #expect(item.status == CareManagement.BatchedOutreachPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newBatchedOutreachPolicy("code-298", name: "name-449")
        try item.moveTo(CareManagement.BatchedOutreachPolicyStatus.inReview)
        #expect(item.status == CareManagement.BatchedOutreachPolicyStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newBatchedOutreachPolicy("code-298", name: "name-449")
        item.status = CareManagement.BatchedOutreachPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedOutreachPolicyStatus.`open`) }
    }
}
