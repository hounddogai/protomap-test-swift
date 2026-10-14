@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialQuotaTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newCredentialQuota("code-284", title: "title-22")
        #expect(item.status == Staffing.CredentialQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Staffing.newCredentialQuota("code-284", title: "title-22")
        try item.moveTo(Staffing.CredentialQuotaStatus.cancelled)
        #expect(item.status == Staffing.CredentialQuotaStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newCredentialQuota("code-284", title: "title-22")
        item.status = Staffing.CredentialQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialQuotaStatus.planned) }
    }
}
