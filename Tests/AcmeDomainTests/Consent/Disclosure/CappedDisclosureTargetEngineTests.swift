@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedDisclosureTargetEngine()
        let item = Consent.newCappedDisclosureTarget("code-900", title: "title-109")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
