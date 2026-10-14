@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultCappedSkillMixManifestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newCappedSkillMixManifest("code-280", label: "label-704")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
