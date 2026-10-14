@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolQuotaTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newFloatPoolQuota("code-771", label: "label-192")
        #expect(item.status == Staffing.FloatPoolQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newFloatPoolQuota("code-771", label: "label-192")
        try item.moveTo(Staffing.FloatPoolQuotaStatus.active)
        #expect(item.status == Staffing.FloatPoolQuotaStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newFloatPoolQuota("code-771", label: "label-192")
        item.status = Staffing.FloatPoolQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolQuotaStatus.draft) }
    }
}
