@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadExceptionEngine()
        let item = Imaging.newReadException("code-536", label: "label-559")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
