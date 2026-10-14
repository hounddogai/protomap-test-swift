@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientOvertimeAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLenientOvertimeAssignmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLenientOvertimeAssignment("code-775", title: "title-961")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
