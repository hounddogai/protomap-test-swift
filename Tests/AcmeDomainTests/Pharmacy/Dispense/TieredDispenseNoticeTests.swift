@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredDispenseNoticeTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newTieredDispenseNotice("code-553", name: "name-335")
        #expect(item.status == Pharmacy.TieredDispenseNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newTieredDispenseNotice("code-553", name: "name-335")
        try item.moveTo(Pharmacy.TieredDispenseNoticeStatus.resolved)
        #expect(item.status == Pharmacy.TieredDispenseNoticeStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newTieredDispenseNotice("code-553", name: "name-335")
        item.status = Pharmacy.TieredDispenseNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredDispenseNoticeStatus.`open`) }
    }
}
