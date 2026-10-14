@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachBundleTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newAdaptiveOutreachBundle("code-162", title: "title-151")
        #expect(item.status == CareManagement.AdaptiveOutreachBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newAdaptiveOutreachBundle("code-162", title: "title-151")
        try item.moveTo(CareManagement.AdaptiveOutreachBundleStatus.inReview)
        #expect(item.status == CareManagement.AdaptiveOutreachBundleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newAdaptiveOutreachBundle("code-162", title: "title-151")
        item.status = CareManagement.AdaptiveOutreachBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveOutreachBundleStatus.`open`) }
    }
}
