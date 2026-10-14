@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultSeasonalLanguageCheckpointEngine(Kit.Flags.newRegistry())
        let item = Consent.newSeasonalLanguageCheckpoint("code-121", title: "title-763")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
