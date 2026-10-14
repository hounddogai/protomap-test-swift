@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadProfileEngine()
        let item = Imaging.newReadProfile("code-895", title: "title-645")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
