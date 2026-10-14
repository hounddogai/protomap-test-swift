@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPrimaryFloatPoolBudgetEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPrimaryFloatPoolBudget("code-218", name: "name-570")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
