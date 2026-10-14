@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusTierTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newLenientCensusTier("code-579", title: "title-668")
        #expect(item.status == BedManagement.LenientCensusTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newLenientCensusTier("code-579", title: "title-668")
        try item.moveTo(BedManagement.LenientCensusTierStatus.reopened)
        #expect(item.status == BedManagement.LenientCensusTierStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newLenientCensusTier("code-579", title: "title-668")
        item.status = BedManagement.LenientCensusTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientCensusTierStatus.`open`) }
    }
}
