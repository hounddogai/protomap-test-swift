@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRegionalStudyRuleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newRegionalStudyRule("code-877", title: "title-332")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
