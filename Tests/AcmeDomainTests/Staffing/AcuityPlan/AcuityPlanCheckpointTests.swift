@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newAcuityPlanCheckpoint("code-265", name: "name-731")
        #expect(item.status == Staffing.AcuityPlanCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newAcuityPlanCheckpoint("code-265", name: "name-731")
        try item.moveTo(Staffing.AcuityPlanCheckpointStatus.scheduled)
        #expect(item.status == Staffing.AcuityPlanCheckpointStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newAcuityPlanCheckpoint("code-265", name: "name-731")
        item.status = Staffing.AcuityPlanCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanCheckpointStatus.planned) }
    }
}
