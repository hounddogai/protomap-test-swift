@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingTieredReadLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultTieredReadLedgerEngine(Kit.Flags.newRegistry())
        let item = Imaging.newTieredReadLedger("code-13", name: "name-724")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
