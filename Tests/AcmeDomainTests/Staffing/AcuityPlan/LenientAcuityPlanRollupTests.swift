@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanRollupTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newLenientAcuityPlanRollup("code-504", label: "label-790")
        #expect(item.status == Staffing.LenientAcuityPlanRollupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newLenientAcuityPlanRollup("code-504", label: "label-790")
        try item.moveTo(Staffing.LenientAcuityPlanRollupStatus.archived)
        #expect(item.status == Staffing.LenientAcuityPlanRollupStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newLenientAcuityPlanRollup("code-504", label: "label-790")
        item.status = Staffing.LenientAcuityPlanRollupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientAcuityPlanRollupStatus.`open`) }
    }
}
