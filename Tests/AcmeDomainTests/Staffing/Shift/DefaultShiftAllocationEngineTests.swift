@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultDefaultShiftAllocationEngine()
        let item = Staffing.newDefaultShiftAllocation("code-147", name: "name-101")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
