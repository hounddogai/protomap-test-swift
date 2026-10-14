@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPrimaryConsentFormSnapshotEngine()
        let item = Consent.newPrimaryConsentFormSnapshot("code-23", label: "label-487")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
