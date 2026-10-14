@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultScheduledDischargePlanAdjustmentEngine()
        let item = BedManagement.newScheduledDischargePlanAdjustment("code-473", title: "title-957")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
