@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramNoticeTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newPendingProgramNotice("code-789", name: "name-488")
        #expect(item.status == CareManagement.PendingProgramNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newPendingProgramNotice("code-789", name: "name-488")
        try item.moveTo(CareManagement.PendingProgramNoticeStatus.rejected)
        #expect(item.status == CareManagement.PendingProgramNoticeStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newPendingProgramNotice("code-789", name: "name-488")
        item.status = CareManagement.PendingProgramNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingProgramNoticeStatus.proposed) }
    }
}
