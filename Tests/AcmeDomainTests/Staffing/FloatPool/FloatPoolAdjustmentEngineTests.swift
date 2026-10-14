@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFloatPoolAdjustmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFloatPoolAdjustment("code-582", label: "label-930")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
