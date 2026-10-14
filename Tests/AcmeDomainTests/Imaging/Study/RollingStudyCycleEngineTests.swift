@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRollingStudyCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultRollingStudyCycleEngine(Kit.Flags.newRegistry())
        let item = Imaging.newRollingStudyCycle("code-649", title: "title-821")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
