@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessThresholdTests {
    @Test func startsInCreated() throws {
        let item = Consent.newWitnessThreshold("code-324", title: "title-216")
        #expect(item.status == Consent.WitnessThresholdStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newWitnessThreshold("code-324", title: "title-216")
        try item.moveTo(Consent.WitnessThresholdStatus.validated)
        #expect(item.status == Consent.WitnessThresholdStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newWitnessThreshold("code-324", title: "title-216")
        item.status = Consent.WitnessThresholdStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessThresholdStatus.created) }
    }
}
