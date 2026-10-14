@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedSubstitutionBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultCappedSubstitutionBaselineEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newCappedSubstitutionBaseline("code-507", name: "name-945")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
