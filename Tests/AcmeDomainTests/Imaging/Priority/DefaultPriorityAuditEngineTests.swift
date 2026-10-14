@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultDefaultPriorityAuditEngine()
        let item = Imaging.newDefaultPriorityAudit("code-148", name: "name-288")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
