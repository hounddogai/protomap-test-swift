@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanClaimTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newAcuityPlanClaim("code-641", name: "name-180")
        #expect(item.status == Staffing.AcuityPlanClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newAcuityPlanClaim("code-641", name: "name-180")
        try item.moveTo(Staffing.AcuityPlanClaimStatus.completed)
        #expect(item.status == Staffing.AcuityPlanClaimStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newAcuityPlanClaim("code-641", name: "name-180")
        item.status = Staffing.AcuityPlanClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanClaimStatus.planned) }
    }
}
