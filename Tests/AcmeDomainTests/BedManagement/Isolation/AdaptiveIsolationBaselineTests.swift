@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationBaselineTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newAdaptiveIsolationBaseline("code-260", label: "label-324")
        #expect(item.status == BedManagement.AdaptiveIsolationBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newAdaptiveIsolationBaseline("code-260", label: "label-324")
        try item.moveTo(BedManagement.AdaptiveIsolationBaselineStatus.inReview)
        #expect(item.status == BedManagement.AdaptiveIsolationBaselineStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newAdaptiveIsolationBaseline("code-260", label: "label-324")
        item.status = BedManagement.AdaptiveIsolationBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveIsolationBaselineStatus.`open`) }
    }
}
