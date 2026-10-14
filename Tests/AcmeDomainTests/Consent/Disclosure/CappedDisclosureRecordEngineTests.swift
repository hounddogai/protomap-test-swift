@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedDisclosureRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedDisclosureRecordEngine()
        let item = Consent.newCappedDisclosureRecord("code-148", label: "label-593")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
