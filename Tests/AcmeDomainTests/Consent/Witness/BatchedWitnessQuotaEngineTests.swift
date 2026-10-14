@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultBatchedWitnessQuotaEngine(Kit.Flags.newRegistry())
        let item = Consent.newBatchedWitnessQuota("code-128", name: "name-636")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
