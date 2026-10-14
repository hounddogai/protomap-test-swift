@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWeightedReadProfileEngine(Kit.Flags.newRegistry())
        let item = Imaging.newWeightedReadProfile("code-709", name: "name-535")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
