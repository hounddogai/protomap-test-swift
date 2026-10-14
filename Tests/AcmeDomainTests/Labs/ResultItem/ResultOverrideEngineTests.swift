@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultOverrideEngine()
        let item = Labs.newResultOverride("code-87", label: "label-57")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
