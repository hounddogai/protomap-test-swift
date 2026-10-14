@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixDigestTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newTieredSkillMixDigest("code-348", label: "label-141")
        #expect(item.status == Staffing.TieredSkillMixDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Staffing.newTieredSkillMixDigest("code-348", label: "label-141")
        try item.moveTo(Staffing.TieredSkillMixDigestStatus.cancelled)
        #expect(item.status == Staffing.TieredSkillMixDigestStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newTieredSkillMixDigest("code-348", label: "label-141")
        item.status = Staffing.TieredSkillMixDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredSkillMixDigestStatus.planned) }
    }
}
