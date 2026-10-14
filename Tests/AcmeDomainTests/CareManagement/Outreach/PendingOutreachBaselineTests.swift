@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingOutreachBaselineTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newPendingOutreachBaseline("code-705", label: "label-651")
        #expect(item.status == CareManagement.PendingOutreachBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newPendingOutreachBaseline("code-705", label: "label-651")
        try item.moveTo(CareManagement.PendingOutreachBaselineStatus.inReview)
        #expect(item.status == CareManagement.PendingOutreachBaselineStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newPendingOutreachBaseline("code-705", label: "label-651")
        item.status = CareManagement.PendingOutreachBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingOutreachBaselineStatus.`open`) }
    }
}
