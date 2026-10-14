@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadAuditEngine(Kit.Flags.newRegistry())
        let item = Imaging.newReadAudit("code-417", label: "label-38")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
