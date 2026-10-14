@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanThresholdTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAcuityPlanThreshold("code-317", name: "name-949")
        #expect(item.status == Staffing.AcuityPlanThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newAcuityPlanThreshold("code-317", name: "name-949")
        try item.moveTo(Staffing.AcuityPlanThresholdStatus.revoked)
        #expect(item.status == Staffing.AcuityPlanThresholdStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAcuityPlanThreshold("code-317", name: "name-949")
        item.status = Staffing.AcuityPlanThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanThresholdStatus.requested) }
    }
}
