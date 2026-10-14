@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientCourierRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientCourierRequestEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientCourierRequest("code-949", label: "label-922")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
