@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictWitnessAssignmentEngine()
        let item = Consent.newStrictWitnessAssignment("code-882", title: "title-636")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
