@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPendingRecallQuotaEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPendingRecallQuota("code-528", name: "name-93")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
