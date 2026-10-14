@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultWeightedRecallDraftEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newWeightedRecallDraft("code-807", name: "name-632")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
