@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultModalityPolicyEngine(Kit.Flags.newRegistry())
        let item = Imaging.newModalityPolicy("code-630", name: "name-754")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
