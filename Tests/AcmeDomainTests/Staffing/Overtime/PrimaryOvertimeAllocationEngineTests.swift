@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPrimaryOvertimeAllocationEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPrimaryOvertimeAllocation("code-192", title: "title-199")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
