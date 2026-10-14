@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPrimaryRecallPlanEngine()
        let item = Pharmacy.newPrimaryRecallPlan("code-599", label: "label-561")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
