@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultManualRecallClaimEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newManualRecallClaim("code-709", title: "title-443")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
