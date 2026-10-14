@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageOverrideTests {
    @Test func startsInIdle() throws {
        let item = Consent.newLanguageOverride("code-624", name: "name-765")
        #expect(item.status == Consent.LanguageOverrideStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newLanguageOverride("code-624", name: "name-765")
        try item.moveTo(Consent.LanguageOverrideStatus.ready)
        #expect(item.status == Consent.LanguageOverrideStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newLanguageOverride("code-624", name: "name-765")
        item.status = Consent.LanguageOverrideStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageOverrideStatus.idle) }
    }
}
