@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyReviewEngine()
        let item = Consent.newProxyReview("code-595", name: "name-867")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
