@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessCycleTests {
    @Test func startsInNew() throws {
        let item = Consent.newCappedWitnessCycle("code-697", title: "title-74")
        #expect(item.status == Consent.CappedWitnessCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Consent.newCappedWitnessCycle("code-697", title: "title-74")
        try item.moveTo(Consent.CappedWitnessCycleStatus.failed)
        #expect(item.status == Consent.CappedWitnessCycleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newCappedWitnessCycle("code-697", title: "title-74")
        item.status = Consent.CappedWitnessCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedWitnessCycleStatus.new) }
    }
}
