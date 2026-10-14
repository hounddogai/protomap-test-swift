@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadQuotaEngine()
        let item = Imaging.newReadQuota("code-686", title: "title-562")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
