@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPrimaryInteractionTemplateEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPrimaryInteractionTemplate("code-216", label: "label-680")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
