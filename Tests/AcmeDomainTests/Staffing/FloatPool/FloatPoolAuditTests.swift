@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAuditTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newFloatPoolAudit("code-328", title: "title-385")
        #expect(item.status == Staffing.FloatPoolAuditStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newFloatPoolAudit("code-328", title: "title-385")
        try item.moveTo(Staffing.FloatPoolAuditStatus.active)
        #expect(item.status == Staffing.FloatPoolAuditStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newFloatPoolAudit("code-328", title: "title-385")
        item.status = Staffing.FloatPoolAuditStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolAuditStatus.draft) }
    }
}
