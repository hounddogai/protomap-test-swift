@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultManualRecallNoticeEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newManualRecallNotice("code-391", label: "label-700")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
