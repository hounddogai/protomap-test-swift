@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFloatPoolTierEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFloatPoolTier("code-246", title: "title-541")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
