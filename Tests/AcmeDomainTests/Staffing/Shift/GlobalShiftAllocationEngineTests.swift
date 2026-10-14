@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultGlobalShiftAllocationEngine()
        let item = Staffing.newGlobalShiftAllocation("code-214", title: "title-48")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
