@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalFloatPoolTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSeasonalFloatPoolTemplateEngine(Kit.Flags.newRegistry())
        let item = Staffing.newSeasonalFloatPoolTemplate("code-119", label: "label-647")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
