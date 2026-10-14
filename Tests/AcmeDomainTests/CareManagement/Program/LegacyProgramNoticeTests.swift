@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramNoticeTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newLegacyProgramNotice("code-493", label: "label-671")
        #expect(item.status == CareManagement.LegacyProgramNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newLegacyProgramNotice("code-493", label: "label-671")
        try item.moveTo(CareManagement.LegacyProgramNoticeStatus.revoked)
        #expect(item.status == CareManagement.LegacyProgramNoticeStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newLegacyProgramNotice("code-493", label: "label-671")
        item.status = CareManagement.LegacyProgramNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyProgramNoticeStatus.requested) }
    }
}
