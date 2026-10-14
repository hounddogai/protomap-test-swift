@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDischargePlanSummaryEngine()
        let item = BedManagement.newDischargePlanSummary("code-768", label: "label-659")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
