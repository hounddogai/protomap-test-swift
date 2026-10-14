@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultRecallDigestEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newRecallDigest("code-9", title: "title-239")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
