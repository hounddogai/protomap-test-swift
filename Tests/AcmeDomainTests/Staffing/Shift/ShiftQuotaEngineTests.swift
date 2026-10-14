@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultShiftQuotaEngine()
        let item = Staffing.newShiftQuota("code-632", name: "name-274")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
