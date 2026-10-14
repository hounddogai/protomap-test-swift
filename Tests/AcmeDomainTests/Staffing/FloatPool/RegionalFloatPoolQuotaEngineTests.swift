@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalFloatPoolQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRegionalFloatPoolQuotaEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRegionalFloatPoolQuota("code-201", title: "title-749")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
