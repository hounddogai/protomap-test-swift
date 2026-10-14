@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanOverrideTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newAcuityPlanOverride("code-881", title: "title-710")
        #expect(item.status == Staffing.AcuityPlanOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newAcuityPlanOverride("code-881", title: "title-710")
        try item.moveTo(Staffing.AcuityPlanOverrideStatus.resolved)
        #expect(item.status == Staffing.AcuityPlanOverrideStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newAcuityPlanOverride("code-881", title: "title-710")
        item.status = Staffing.AcuityPlanOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanOverrideStatus.`open`) }
    }
}
