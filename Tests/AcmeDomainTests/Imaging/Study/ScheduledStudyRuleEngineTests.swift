@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultScheduledStudyRuleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newScheduledStudyRule("code-135", title: "title-567")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
