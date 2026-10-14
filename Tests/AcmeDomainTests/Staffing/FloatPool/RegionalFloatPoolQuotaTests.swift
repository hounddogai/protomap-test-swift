@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolQuotaTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newRegionalFloatPoolQuota("code-201", title: "title-749")
        #expect(item.status == Staffing.RegionalFloatPoolQuotaStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newRegionalFloatPoolQuota("code-201", title: "title-749")
        try item.moveTo(Staffing.RegionalFloatPoolQuotaStatus.revoked)
        #expect(item.status == Staffing.RegionalFloatPoolQuotaStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newRegionalFloatPoolQuota("code-201", title: "title-749")
        item.status = Staffing.RegionalFloatPoolQuotaStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalFloatPoolQuotaStatus.requested) }
    }
}
