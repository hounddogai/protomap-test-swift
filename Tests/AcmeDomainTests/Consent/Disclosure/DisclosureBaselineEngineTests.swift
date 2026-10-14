@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDisclosureBaselineEngine()
        let item = Consent.newDisclosureBaseline("code-122", label: "label-810")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
