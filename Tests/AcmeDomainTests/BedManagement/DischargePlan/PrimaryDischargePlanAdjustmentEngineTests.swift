@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPrimaryDischargePlanAdjustmentEngine()
        let item = BedManagement.newPrimaryDischargePlanAdjustment("code-205", title: "title-474")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
