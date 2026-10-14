@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingAdaptivePriorityAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultAdaptivePriorityAuditEngine()
        let item = Imaging.newAdaptivePriorityAudit("code-54", name: "name-128")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
