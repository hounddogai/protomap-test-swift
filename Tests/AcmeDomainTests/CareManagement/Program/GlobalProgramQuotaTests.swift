@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramQuotaTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newGlobalProgramQuota("code-503", title: "title-363")
        #expect(item.status == CareManagement.GlobalProgramQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newGlobalProgramQuota("code-503", title: "title-363")
        try item.moveTo(CareManagement.GlobalProgramQuotaStatus.approved)
        #expect(item.status == CareManagement.GlobalProgramQuotaStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newGlobalProgramQuota("code-503", title: "title-363")
        item.status = CareManagement.GlobalProgramQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalProgramQuotaStatus.proposed) }
    }
}
