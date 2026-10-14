@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredRevocationBaselineTests {
    @Test func startsInNew() throws {
        let item = Consent.newTieredRevocationBaseline("code-972", name: "name-87")
        #expect(item.status == Consent.TieredRevocationBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newTieredRevocationBaseline("code-972", name: "name-87")
        try item.moveTo(Consent.TieredRevocationBaselineStatus.running)
        #expect(item.status == Consent.TieredRevocationBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newTieredRevocationBaseline("code-972", name: "name-87")
        item.status = Consent.TieredRevocationBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredRevocationBaselineStatus.new) }
    }
}
