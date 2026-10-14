@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredProxyCycleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newTieredProxyCycle("code-206", name: "name-590")
        #expect(item.status == Consent.TieredProxyCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newTieredProxyCycle("code-206", name: "name-590")
        try item.moveTo(Consent.TieredProxyCycleStatus.granted)
        #expect(item.status == Consent.TieredProxyCycleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newTieredProxyCycle("code-206", name: "name-590")
        item.status = Consent.TieredProxyCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredProxyCycleStatus.requested) }
    }
}
