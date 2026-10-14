@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanLedgerTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newPrimaryDischargePlanLedger("code-503", title: "title-922")
        #expect(item.status == BedManagement.PrimaryDischargePlanLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newPrimaryDischargePlanLedger("code-503", title: "title-922")
        try item.moveTo(BedManagement.PrimaryDischargePlanLedgerStatus.inReview)
        #expect(item.status == BedManagement.PrimaryDischargePlanLedgerStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newPrimaryDischargePlanLedger("code-503", title: "title-922")
        item.status = BedManagement.PrimaryDischargePlanLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryDischargePlanLedgerStatus.`open`) }
    }
}
