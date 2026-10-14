@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessPlanTests {
    @Test func startsInNew() throws {
        let item = Consent.newWitnessPlan("code-50", label: "label-508")
        #expect(item.status == Consent.WitnessPlanStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newWitnessPlan("code-50", label: "label-508")
        try item.moveTo(Consent.WitnessPlanStatus.queued)
        #expect(item.status == Consent.WitnessPlanStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newWitnessPlan("code-50", label: "label-508")
        item.status = Consent.WitnessPlanStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessPlanStatus.new) }
    }
}
