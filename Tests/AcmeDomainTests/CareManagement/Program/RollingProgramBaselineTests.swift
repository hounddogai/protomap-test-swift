@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramBaselineTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRollingProgramBaseline("code-907", title: "title-15")
        #expect(item.status == CareManagement.RollingProgramBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = CareManagement.newRollingProgramBaseline("code-907", title: "title-15")
        try item.moveTo(CareManagement.RollingProgramBaselineStatus.closed)
        #expect(item.status == CareManagement.RollingProgramBaselineStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRollingProgramBaseline("code-907", title: "title-15")
        item.status = CareManagement.RollingProgramBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingProgramBaselineStatus.draft) }
    }
}
