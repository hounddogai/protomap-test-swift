@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRegionalOvertimeEntryEngine()
        let item = Staffing.newRegionalOvertimeEntry("code-850", name: "name-607")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
