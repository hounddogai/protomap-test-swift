@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessBaselineTests {
    @Test func startsInNew() throws {
        let item = Consent.newDefaultWitnessBaseline("code-577", name: "name-896")
        #expect(item.status == Consent.DefaultWitnessBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newDefaultWitnessBaseline("code-577", name: "name-896")
        try item.moveTo(Consent.DefaultWitnessBaselineStatus.running)
        #expect(item.status == Consent.DefaultWitnessBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newDefaultWitnessBaseline("code-577", name: "name-896")
        item.status = Consent.DefaultWitnessBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultWitnessBaselineStatus.new) }
    }
}
