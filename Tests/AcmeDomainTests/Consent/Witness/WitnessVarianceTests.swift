@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessVarianceTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWitnessVariance("code-45", label: "label-757")
        #expect(item.status == Consent.WitnessVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Consent.newWitnessVariance("code-45", label: "label-757")
        try item.moveTo(Consent.WitnessVarianceStatus.suspended)
        #expect(item.status == Consent.WitnessVarianceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWitnessVariance("code-45", label: "label-757")
        item.status = Consent.WitnessVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessVarianceStatus.draft) }
    }
}
