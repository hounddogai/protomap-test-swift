@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessCycleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newWitnessCycle("code-815", name: "name-125")
        #expect(item.status == Consent.WitnessCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newWitnessCycle("code-815", name: "name-125")
        try item.moveTo(Consent.WitnessCycleStatus.granted)
        #expect(item.status == Consent.WitnessCycleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newWitnessCycle("code-815", name: "name-125")
        item.status = Consent.WitnessCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessCycleStatus.requested) }
    }
}
