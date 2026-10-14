@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyAuditTests {
    @Test func startsInProposed() throws {
        let item = Consent.newRollingProxyAudit("code-723", name: "name-215")
        #expect(item.status == Consent.RollingProxyAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newRollingProxyAudit("code-723", name: "name-215")
        try item.moveTo(Consent.RollingProxyAuditStatus.rejected)
        #expect(item.status == Consent.RollingProxyAuditStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newRollingProxyAudit("code-723", name: "name-215")
        item.status = Consent.RollingProxyAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingProxyAuditStatus.proposed) }
    }
}
