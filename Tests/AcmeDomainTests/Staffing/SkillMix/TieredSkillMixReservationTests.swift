@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixReservationTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newTieredSkillMixReservation("code-172", title: "title-874")
        #expect(item.status == Staffing.TieredSkillMixReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newTieredSkillMixReservation("code-172", title: "title-874")
        try item.moveTo(Staffing.TieredSkillMixReservationStatus.revoked)
        #expect(item.status == Staffing.TieredSkillMixReservationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newTieredSkillMixReservation("code-172", title: "title-874")
        item.status = Staffing.TieredSkillMixReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredSkillMixReservationStatus.requested) }
    }
}
