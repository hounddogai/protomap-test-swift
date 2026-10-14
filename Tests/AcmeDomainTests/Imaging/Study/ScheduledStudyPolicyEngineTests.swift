@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultScheduledStudyPolicyEngine(Kit.Flags.newRegistry())
        let item = Imaging.newScheduledStudyPolicy("code-722", label: "label-341")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
