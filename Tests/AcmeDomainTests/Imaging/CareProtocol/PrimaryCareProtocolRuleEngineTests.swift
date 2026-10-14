@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryCareProtocolRuleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrimaryCareProtocolRule("code-942", title: "title-734")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
