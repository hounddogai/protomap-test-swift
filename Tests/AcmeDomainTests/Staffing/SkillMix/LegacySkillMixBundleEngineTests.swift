@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacySkillMixBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLegacySkillMixBundleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLegacySkillMixBundle("code-380", label: "label-25")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
