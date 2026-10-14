@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictLanguageAssignmentEngine(Kit.Flags.newRegistry())
        let item = Consent.newStrictLanguageAssignment("code-192", title: "title-281")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
