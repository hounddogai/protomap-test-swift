@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageThresholdTests {
    @Test func startsInProposed() throws {
        let item = Consent.newWeightedLanguageThreshold("code-36", name: "name-697")
        #expect(item.status == Consent.WeightedLanguageThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Consent.newWeightedLanguageThreshold("code-36", name: "name-697")
        try item.moveTo(Consent.WeightedLanguageThresholdStatus.withdrawn)
        #expect(item.status == Consent.WeightedLanguageThresholdStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newWeightedLanguageThreshold("code-36", name: "name-697")
        item.status = Consent.WeightedLanguageThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedLanguageThresholdStatus.proposed) }
    }
}
