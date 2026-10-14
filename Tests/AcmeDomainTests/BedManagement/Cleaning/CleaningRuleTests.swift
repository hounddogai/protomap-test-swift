@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRuleTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newCleaningRule("code-305", name: "name-894")
        #expect(item.status == BedManagement.CleaningRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newCleaningRule("code-305", name: "name-894")
        try item.moveTo(BedManagement.CleaningRuleStatus.expired)
        #expect(item.status == BedManagement.CleaningRuleStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newCleaningRule("code-305", name: "name-894")
        item.status = BedManagement.CleaningRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningRuleStatus.requested) }
    }
}
