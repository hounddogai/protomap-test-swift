@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingSubstitutionAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPendingSubstitutionAllocationEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPendingSubstitutionAllocation("code-552", title: "title-461")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
