@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientProxyReviewEngine(Kit.Flags.newRegistry())
        let item = Consent.newLenientProxyReview("code-861", label: "label-575")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
