@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientWitnessVarianceTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLenientWitnessVariance("code-609", name: "name-107")
        #expect(item.status == Consent.LenientWitnessVarianceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newLenientWitnessVariance("code-609", name: "name-107")
        try item.moveTo(Consent.LenientWitnessVarianceStatus.rejected)
        #expect(item.status == Consent.LenientWitnessVarianceStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLenientWitnessVariance("code-609", name: "name-107")
        item.status = Consent.LenientWitnessVarianceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LenientWitnessVarianceStatus.proposed) }
    }
}
