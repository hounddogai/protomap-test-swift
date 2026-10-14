@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramQuotaTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newTieredProgramQuota("code-471", name: "name-767")
        #expect(item.status == CareManagement.TieredProgramQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = CareManagement.newTieredProgramQuota("code-471", name: "name-767")
        try item.moveTo(CareManagement.TieredProgramQuotaStatus.withdrawn)
        #expect(item.status == CareManagement.TieredProgramQuotaStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newTieredProgramQuota("code-471", name: "name-767")
        item.status = CareManagement.TieredProgramQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredProgramQuotaStatus.proposed) }
    }
}
