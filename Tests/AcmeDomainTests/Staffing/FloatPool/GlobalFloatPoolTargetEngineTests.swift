@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalFloatPoolTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultGlobalFloatPoolTargetEngine(Kit.Flags.newRegistry())
        let item = Staffing.newGlobalFloatPoolTarget("code-262", name: "name-359")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
