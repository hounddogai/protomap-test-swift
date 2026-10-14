@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramTargetTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newPendingProgramTarget("code-579", name: "name-661")
        #expect(item.status == CareManagement.PendingProgramTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newPendingProgramTarget("code-579", name: "name-661")
        try item.moveTo(CareManagement.PendingProgramTargetStatus.expired)
        #expect(item.status == CareManagement.PendingProgramTargetStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newPendingProgramTarget("code-579", name: "name-661")
        item.status = CareManagement.PendingProgramTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingProgramTargetStatus.requested) }
    }
}
