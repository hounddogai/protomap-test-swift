@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialPlanTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newWeightedCredentialPlan("code-931", name: "name-370")
        #expect(item.status == Staffing.WeightedCredentialPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newWeightedCredentialPlan("code-931", name: "name-370")
        try item.moveTo(Staffing.WeightedCredentialPlanStatus.validated)
        #expect(item.status == Staffing.WeightedCredentialPlanStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newWeightedCredentialPlan("code-931", name: "name-370")
        item.status = Staffing.WeightedCredentialPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedCredentialPlanStatus.created) }
    }
}
