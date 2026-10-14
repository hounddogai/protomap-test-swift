@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultRegionalSkillMixLedgerEngine(Kit.Flags.newRegistry())
        let item = Staffing.newRegionalSkillMixLedger("code-139", title: "title-707")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
