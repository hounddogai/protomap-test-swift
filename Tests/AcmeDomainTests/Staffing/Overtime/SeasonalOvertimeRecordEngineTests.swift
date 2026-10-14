@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalOvertimeRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSeasonalOvertimeRecordEngine()
        let item = Staffing.newSeasonalOvertimeRecord("code-708", label: "label-490")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
