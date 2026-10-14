@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularySnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLegacyFormularySnapshotEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newLegacyFormularySnapshot("code-207", title: "title-928")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
