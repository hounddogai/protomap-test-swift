@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultCappedModalityPolicyEngine()
        let item = Imaging.newCappedModalityPolicy("code-618", label: "label-354")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
