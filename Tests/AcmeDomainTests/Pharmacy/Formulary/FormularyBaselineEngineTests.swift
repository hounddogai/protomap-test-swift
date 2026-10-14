@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultFormularyBaselineEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newFormularyBaseline("code-635", title: "title-346")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
