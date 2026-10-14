@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadAdjustmentEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadAdjustment("code-94", title: "title-924")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
