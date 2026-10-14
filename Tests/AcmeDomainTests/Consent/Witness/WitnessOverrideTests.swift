@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessOverrideTests {
    @Test func startsInNew() throws {
        let item = Consent.newWitnessOverride("code-134", title: "title-641")
        #expect(item.status == Consent.WitnessOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newWitnessOverride("code-134", title: "title-641")
        try item.moveTo(Consent.WitnessOverrideStatus.queued)
        #expect(item.status == Consent.WitnessOverrideStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newWitnessOverride("code-134", title: "title-641")
        item.status = Consent.WitnessOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessOverrideStatus.new) }
    }
}
