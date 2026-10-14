@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLegacyRecallRecordEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newLegacyRecallRecord("code-626", title: "title-254")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
