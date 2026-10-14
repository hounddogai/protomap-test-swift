@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalSubstitutionTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultGlobalSubstitutionTargetEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newGlobalSubstitutionTarget("code-617", name: "name-203")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
