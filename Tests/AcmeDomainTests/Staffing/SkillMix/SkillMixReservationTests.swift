@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixReservationTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newSkillMixReservation("code-273", label: "label-295")
        #expect(item.status == Staffing.SkillMixReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newSkillMixReservation("code-273", label: "label-295")
        try item.moveTo(Staffing.SkillMixReservationStatus.scheduled)
        #expect(item.status == Staffing.SkillMixReservationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newSkillMixReservation("code-273", label: "label-295")
        item.status = Staffing.SkillMixReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixReservationStatus.planned) }
    }
}
