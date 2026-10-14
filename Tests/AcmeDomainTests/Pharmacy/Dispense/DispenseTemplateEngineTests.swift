@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultDispenseTemplateEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newDispenseTemplate("code-88", name: "name-718")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
