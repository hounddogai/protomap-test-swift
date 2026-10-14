@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadLedgerEngine()
        let item = Imaging.newReadLedger("code-430", title: "title-902")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
