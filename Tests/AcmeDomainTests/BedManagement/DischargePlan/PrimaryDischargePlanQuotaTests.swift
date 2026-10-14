@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanQuotaTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newPrimaryDischargePlanQuota("code-774", name: "name-507")
        #expect(item.status == BedManagement.PrimaryDischargePlanQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newPrimaryDischargePlanQuota("code-774", name: "name-507")
        try item.moveTo(BedManagement.PrimaryDischargePlanQuotaStatus.validated)
        #expect(item.status == BedManagement.PrimaryDischargePlanQuotaStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newPrimaryDischargePlanQuota("code-774", name: "name-507")
        item.status = BedManagement.PrimaryDischargePlanQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryDischargePlanQuotaStatus.created) }
    }
}
