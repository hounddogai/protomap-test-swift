@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultScheduledFloatPoolAuditEngine(Kit.Flags.newRegistry())
        let item = Staffing.newScheduledFloatPoolAudit("code-898", label: "label-291")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
