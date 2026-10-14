@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadRequestEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadRequest("code-666", name: "name-593")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
