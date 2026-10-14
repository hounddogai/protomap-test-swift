@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBundleTests {
    @Test func startsInIdle() throws {
        let item = Consent.newWitnessBundle("code-40", label: "label-28")
        #expect(item.status == Consent.WitnessBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Consent.newWitnessBundle("code-40", label: "label-28")
        try item.moveTo(Consent.WitnessBundleStatus.stopped)
        #expect(item.status == Consent.WitnessBundleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newWitnessBundle("code-40", label: "label-28")
        item.status = Consent.WitnessBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessBundleStatus.idle) }
    }
}
