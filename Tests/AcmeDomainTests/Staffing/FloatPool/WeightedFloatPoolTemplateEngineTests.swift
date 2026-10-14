@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedFloatPoolTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultWeightedFloatPoolTemplateEngine(Kit.Flags.newRegistry())
        let item = Staffing.newWeightedFloatPoolTemplate("code-437", name: "name-519")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
