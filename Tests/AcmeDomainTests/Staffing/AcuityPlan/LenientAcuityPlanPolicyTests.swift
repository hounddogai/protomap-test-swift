@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanPolicyTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLenientAcuityPlanPolicy("code-345", label: "label-930")
        #expect(item.status == Staffing.LenientAcuityPlanPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newLenientAcuityPlanPolicy("code-345", label: "label-930")
        try item.moveTo(Staffing.LenientAcuityPlanPolicyStatus.running)
        #expect(item.status == Staffing.LenientAcuityPlanPolicyStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLenientAcuityPlanPolicy("code-345", label: "label-930")
        item.status = Staffing.LenientAcuityPlanPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientAcuityPlanPolicyStatus.new) }
    }
}
