@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSkillMixLedgerEngine(Kit.Flags.newRegistry())
        let item = Staffing.newSkillMixLedger("code-703", label: "label-633")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
