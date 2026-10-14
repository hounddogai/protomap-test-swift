@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusQuotaTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newGlobalCensusQuota("code-269", name: "name-560")
        #expect(item.status == BedManagement.GlobalCensusQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newGlobalCensusQuota("code-269", name: "name-560")
        try item.moveTo(BedManagement.GlobalCensusQuotaStatus.withdrawn)
        #expect(item.status == BedManagement.GlobalCensusQuotaStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newGlobalCensusQuota("code-269", name: "name-560")
        item.status = BedManagement.GlobalCensusQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalCensusQuotaStatus.proposed) }
    }
}
