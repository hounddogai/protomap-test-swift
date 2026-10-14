@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramQuotaTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newProgramQuota("code-766", name: "name-849")
        #expect(item.status == CareManagement.ProgramQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newProgramQuota("code-766", name: "name-849")
        try item.moveTo(CareManagement.ProgramQuotaStatus.expired)
        #expect(item.status == CareManagement.ProgramQuotaStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newProgramQuota("code-766", name: "name-849")
        item.status = CareManagement.ProgramQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramQuotaStatus.requested) }
    }
}
