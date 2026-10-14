@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWitnessCheckpointEngine(Kit.Flags.newRegistry())
        let item = Consent.newWitnessCheckpoint("code-552", title: "title-691")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
