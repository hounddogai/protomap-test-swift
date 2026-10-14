@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualOvertimeVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultManualOvertimeVarianceEngine(Kit.Flags.newRegistry())
        let item = Staffing.newManualOvertimeVariance("code-77", label: "label-542")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
