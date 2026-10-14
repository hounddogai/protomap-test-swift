@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultShiftAuditEngine()
        let item = Staffing.newShiftAudit("code-717", title: "title-723")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
