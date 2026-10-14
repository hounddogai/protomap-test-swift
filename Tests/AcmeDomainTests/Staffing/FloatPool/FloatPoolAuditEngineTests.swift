@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFloatPoolAuditEngine()
        let item = Staffing.newFloatPoolAudit("code-328", title: "title-385")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
