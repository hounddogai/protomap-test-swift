@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingCareProtocolExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPendingCareProtocolExceptionEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPendingCareProtocolException("code-663", name: "name-668")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
