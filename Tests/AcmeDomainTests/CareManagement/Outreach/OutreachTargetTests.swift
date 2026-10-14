@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachTargetTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newOutreachTarget("code-863", title: "title-988")
        #expect(item.status == CareManagement.OutreachTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newOutreachTarget("code-863", title: "title-988")
        try item.moveTo(CareManagement.OutreachTargetStatus.revoked)
        #expect(item.status == CareManagement.OutreachTargetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newOutreachTarget("code-863", title: "title-988")
        item.status = CareManagement.OutreachTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachTargetStatus.requested) }
    }
}
