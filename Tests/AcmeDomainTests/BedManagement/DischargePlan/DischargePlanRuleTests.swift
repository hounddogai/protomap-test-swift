@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanRuleTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDischargePlanRule("code-436", title: "title-259")
        #expect(item.status == BedManagement.DischargePlanRuleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newDischargePlanRule("code-436", title: "title-259")
        try item.moveTo(BedManagement.DischargePlanRuleStatus.granted)
        #expect(item.status == BedManagement.DischargePlanRuleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDischargePlanRule("code-436", title: "title-259")
        item.status = BedManagement.DischargePlanRuleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanRuleStatus.requested) }
    }
}
