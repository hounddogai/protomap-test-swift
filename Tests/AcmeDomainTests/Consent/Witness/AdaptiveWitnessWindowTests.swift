@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveWitnessWindowTests {
    @Test func startsInNew() throws {
        let item = Consent.newAdaptiveWitnessWindow("code-524", label: "label-615")
        #expect(item.status == Consent.AdaptiveWitnessWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newAdaptiveWitnessWindow("code-524", label: "label-615")
        try item.moveTo(Consent.AdaptiveWitnessWindowStatus.queued)
        #expect(item.status == Consent.AdaptiveWitnessWindowStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newAdaptiveWitnessWindow("code-524", label: "label-615")
        item.status = Consent.AdaptiveWitnessWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveWitnessWindowStatus.new) }
    }
}
