@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosurePlanTests {
    @Test func startsInProposed() throws {
        let item = Consent.newBatchedDisclosurePlan("code-815", title: "title-629")
        #expect(item.status == Consent.BatchedDisclosurePlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newBatchedDisclosurePlan("code-815", title: "title-629")
        try item.moveTo(Consent.BatchedDisclosurePlanStatus.approved)
        #expect(item.status == Consent.BatchedDisclosurePlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newBatchedDisclosurePlan("code-815", title: "title-629")
        item.status = Consent.BatchedDisclosurePlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedDisclosurePlanStatus.proposed) }
    }
}
