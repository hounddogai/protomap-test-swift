@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingWitnessReviewEngine(Kit.Flags.newRegistry())
        let item = Consent.newRollingWitnessReview("code-539", name: "name-746")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
