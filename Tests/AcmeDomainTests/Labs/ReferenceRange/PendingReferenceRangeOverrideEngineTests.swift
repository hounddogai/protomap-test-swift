@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingReferenceRangeOverrideEngine()
        let item = Labs.newPendingReferenceRangeOverride("code-65", label: "label-265")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
