@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalSubstitutionScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultGlobalSubstitutionScoreEngine()
        let item = Pharmacy.newGlobalSubstitutionScore("code-656", title: "title-465")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
