@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultScheduledCleaningPlanEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newScheduledCleaningPlan("code-317", title: "title-132")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
