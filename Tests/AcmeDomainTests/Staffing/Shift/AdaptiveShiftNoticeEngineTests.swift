@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAdaptiveShiftNoticeEngine()
        let item = Staffing.newAdaptiveShiftNotice("code-810", title: "title-996")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
