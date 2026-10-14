@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationBaselineTests {
    @Test func startsInNew() throws {
        let item = Consent.newRevocationBaseline("code-930", label: "label-158")
        #expect(item.status == Consent.RevocationBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newRevocationBaseline("code-930", label: "label-158")
        try item.moveTo(Consent.RevocationBaselineStatus.running)
        #expect(item.status == Consent.RevocationBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newRevocationBaseline("code-930", label: "label-158")
        item.status = Consent.RevocationBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationBaselineStatus.new) }
    }
}
