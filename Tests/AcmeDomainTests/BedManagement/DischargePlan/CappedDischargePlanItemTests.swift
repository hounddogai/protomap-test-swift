@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedDischargePlanItemTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCappedDischargePlanItem("code-89", name: "name-724")
        #expect(item.status == BedManagement.CappedDischargePlanItemStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newCappedDischargePlanItem("code-89", name: "name-724")
        try item.moveTo(BedManagement.CappedDischargePlanItemStatus.inReview)
        #expect(item.status == BedManagement.CappedDischargePlanItemStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCappedDischargePlanItem("code-89", name: "name-724")
        item.status = BedManagement.CappedDischargePlanItemStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedDischargePlanItemStatus.`open`) }
    }
}
