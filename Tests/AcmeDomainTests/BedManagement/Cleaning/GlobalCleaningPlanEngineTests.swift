@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCleaningPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultGlobalCleaningPlanEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newGlobalCleaningPlan("code-321", title: "title-582")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
