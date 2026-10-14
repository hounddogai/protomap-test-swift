@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredDispenseNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultTieredDispenseNoticeEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newTieredDispenseNotice("code-553", name: "name-335")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
