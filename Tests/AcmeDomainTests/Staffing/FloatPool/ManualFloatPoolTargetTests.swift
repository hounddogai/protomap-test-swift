@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualFloatPoolTargetTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newManualFloatPoolTarget("code-488", name: "name-64")
        #expect(item.status == Staffing.ManualFloatPoolTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newManualFloatPoolTarget("code-488", name: "name-64")
        try item.moveTo(Staffing.ManualFloatPoolTargetStatus.approved)
        #expect(item.status == Staffing.ManualFloatPoolTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newManualFloatPoolTarget("code-488", name: "name-64")
        item.status = Staffing.ManualFloatPoolTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualFloatPoolTargetStatus.proposed) }
    }
}
