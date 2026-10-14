@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryCareProtocolScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryCareProtocolScoreEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrimaryCareProtocolScore("code-935", name: "name-346")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
