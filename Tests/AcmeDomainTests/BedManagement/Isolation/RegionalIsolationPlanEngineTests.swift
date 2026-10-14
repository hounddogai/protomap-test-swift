@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalIsolationPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRegionalIsolationPlanEngine()
        let item = BedManagement.newRegionalIsolationPlan("code-629", title: "title-279")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
