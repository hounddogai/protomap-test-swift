@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAdaptiveSpecimenBundleEngine(Kit.Flags.newRegistry())
        let item = Labs.newAdaptiveSpecimenBundle("code-277", label: "label-879")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
