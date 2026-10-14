@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPrimaryLanguageAssignmentEngine()
        let item = Consent.newPrimaryLanguageAssignment("code-882", name: "name-695")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
