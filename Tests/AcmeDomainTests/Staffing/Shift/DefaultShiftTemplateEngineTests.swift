@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultDefaultShiftTemplateEngine()
        let item = Staffing.newDefaultShiftTemplate("code-523", label: "label-190")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
