@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackWitnessDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultFallbackWitnessDraftEngine()
        let item = Consent.newFallbackWitnessDraft("code-932", title: "title-518")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
