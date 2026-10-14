@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveFloatPoolCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAdaptiveFloatPoolCycleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newAdaptiveFloatPoolCycle("code-996", label: "label-59")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
