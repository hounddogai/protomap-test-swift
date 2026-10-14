@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultGlobalShiftTemplateEngine(Kit.Flags.newRegistry())
        let item = Staffing.newGlobalShiftTemplate("code-606", label: "label-987")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
