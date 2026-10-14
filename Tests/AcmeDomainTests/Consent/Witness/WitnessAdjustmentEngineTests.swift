@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWitnessAdjustmentEngine(Kit.Flags.newRegistry())
        let item = Consent.newWitnessAdjustment("code-961", title: "title-51")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
