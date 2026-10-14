@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictDischargePlanPolicyTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newStrictDischargePlanPolicy("code-834", name: "name-231")
        #expect(item.status == BedManagement.StrictDischargePlanPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newStrictDischargePlanPolicy("code-834", name: "name-231")
        try item.moveTo(BedManagement.StrictDischargePlanPolicyStatus.rejected)
        #expect(item.status == BedManagement.StrictDischargePlanPolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newStrictDischargePlanPolicy("code-834", name: "name-231")
        item.status = BedManagement.StrictDischargePlanPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictDischargePlanPolicyStatus.proposed) }
    }
}
