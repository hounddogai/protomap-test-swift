@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachScoreTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newOutreachScore("code-829", label: "label-156")
        #expect(item.status == CareManagement.OutreachScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newOutreachScore("code-829", label: "label-156")
        try item.moveTo(CareManagement.OutreachScoreStatus.approved)
        #expect(item.status == CareManagement.OutreachScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newOutreachScore("code-829", label: "label-156")
        item.status = CareManagement.OutreachScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachScoreStatus.proposed) }
    }
}
