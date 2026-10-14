@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultGlobalConsentFormBatchEngine()
        let item = Consent.newGlobalConsentFormBatch("code-521", name: "name-541")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
