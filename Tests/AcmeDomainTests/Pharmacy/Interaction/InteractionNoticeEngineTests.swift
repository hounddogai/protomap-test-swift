@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultInteractionNoticeEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newInteractionNotice("code-380", label: "label-352")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
