@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLenientShiftQuotaEngine()
        let item = Staffing.newLenientShiftQuota("code-853", label: "label-183")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
