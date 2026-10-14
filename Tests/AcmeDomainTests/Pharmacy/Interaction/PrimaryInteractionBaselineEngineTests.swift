@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPrimaryInteractionBaselineEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPrimaryInteractionBaseline("code-203", label: "label-167")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
