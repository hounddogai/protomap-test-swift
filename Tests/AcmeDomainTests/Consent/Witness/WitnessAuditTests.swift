@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAuditTests {
    @Test func startsInNew() throws {
        let item = Consent.newWitnessAudit("code-272", title: "title-483")
        #expect(item.status == Consent.WitnessAuditStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newWitnessAudit("code-272", title: "title-483")
        try item.moveTo(Consent.WitnessAuditStatus.queued)
        #expect(item.status == Consent.WitnessAuditStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newWitnessAudit("code-272", title: "title-483")
        item.status = Consent.WitnessAuditStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessAuditStatus.new) }
    }
}
