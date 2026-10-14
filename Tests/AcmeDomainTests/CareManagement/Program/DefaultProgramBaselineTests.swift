@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultProgramBaselineTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newDefaultProgramBaseline("code-883", label: "label-405")
        #expect(item.status == CareManagement.DefaultProgramBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newDefaultProgramBaseline("code-883", label: "label-405")
        try item.moveTo(CareManagement.DefaultProgramBaselineStatus.revoked)
        #expect(item.status == CareManagement.DefaultProgramBaselineStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newDefaultProgramBaseline("code-883", label: "label-405")
        item.status = CareManagement.DefaultProgramBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultProgramBaselineStatus.requested) }
    }
}
