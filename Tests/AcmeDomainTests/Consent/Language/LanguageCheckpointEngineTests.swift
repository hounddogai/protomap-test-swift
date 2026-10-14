@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguageCheckpointEngine()
        let item = Consent.newLanguageCheckpoint("code-173", name: "name-734")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
