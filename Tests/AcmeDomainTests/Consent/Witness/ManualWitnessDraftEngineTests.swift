@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultManualWitnessDraftEngine()
        let item = Consent.newManualWitnessDraft("code-723", title: "title-744")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
