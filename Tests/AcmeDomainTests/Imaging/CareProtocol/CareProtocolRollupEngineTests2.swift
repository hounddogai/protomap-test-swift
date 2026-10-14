@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCareProtocolRollupEngine()
        let item = Imaging.newCareProtocolRollup("code-189", name: "name-337")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
