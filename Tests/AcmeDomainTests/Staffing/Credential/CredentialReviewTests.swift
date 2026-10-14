@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialReviewTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCredentialReview("code-291", title: "title-474")
        #expect(item.status == Staffing.CredentialReviewStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newCredentialReview("code-291", title: "title-474")
        try item.moveTo(Staffing.CredentialReviewStatus.rejected)
        #expect(item.status == Staffing.CredentialReviewStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCredentialReview("code-291", title: "title-474")
        item.status = Staffing.CredentialReviewStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialReviewStatus.proposed) }
    }
}
