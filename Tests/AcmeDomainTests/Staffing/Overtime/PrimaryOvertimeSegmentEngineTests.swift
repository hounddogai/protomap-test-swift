@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPrimaryOvertimeSegmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPrimaryOvertimeSegment("code-762", name: "name-115")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
