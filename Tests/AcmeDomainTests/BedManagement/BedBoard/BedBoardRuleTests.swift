@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRuleTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newBedBoardRule("code-273", name: "name-61")
        #expect(item.status == BedManagement.BedBoardRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = BedManagement.newBedBoardRule("code-273", name: "name-61")
        try item.moveTo(BedManagement.BedBoardRuleStatus.archived)
        #expect(item.status == BedManagement.BedBoardRuleStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newBedBoardRule("code-273", name: "name-61")
        item.status = BedManagement.BedBoardRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardRuleStatus.`open`) }
    }
}
