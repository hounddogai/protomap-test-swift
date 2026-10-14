@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultAdaptiveSkillMixManifestEngine(Kit.Flags.newRegistry())
        let item = Staffing.newAdaptiveSkillMixManifest("code-727", title: "title-991")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
