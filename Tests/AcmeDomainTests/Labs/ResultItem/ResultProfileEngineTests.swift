@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultProfileEngine()
        let item = Labs.newResultProfile("code-583", label: "label-274")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
