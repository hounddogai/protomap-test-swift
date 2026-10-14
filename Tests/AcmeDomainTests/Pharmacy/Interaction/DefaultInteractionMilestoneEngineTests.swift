@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultDefaultInteractionMilestoneEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newDefaultInteractionMilestone("code-241", label: "label-749")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
