@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryOutreachReviewTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newPrimaryOutreachReview("code-674", label: "label-647")
        #expect(item.status == CareManagement.PrimaryOutreachReviewStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newPrimaryOutreachReview("code-674", label: "label-647")
        try item.moveTo(CareManagement.PrimaryOutreachReviewStatus.inReview)
        #expect(item.status == CareManagement.PrimaryOutreachReviewStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newPrimaryOutreachReview("code-674", label: "label-647")
        item.status = CareManagement.PrimaryOutreachReviewStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryOutreachReviewStatus.`open`) }
    }
}
