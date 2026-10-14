@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessPlanTests {
    @Test func startsInNew() throws {
        let item = Consent.newCappedWitnessPlan("code-609", title: "title-131")
        #expect(item.status == Consent.CappedWitnessPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newCappedWitnessPlan("code-609", title: "title-131")
        try item.moveTo(Consent.CappedWitnessPlanStatus.running)
        #expect(item.status == Consent.CappedWitnessPlanStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newCappedWitnessPlan("code-609", title: "title-131")
        item.status = Consent.CappedWitnessPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedWitnessPlanStatus.new) }
    }
}
