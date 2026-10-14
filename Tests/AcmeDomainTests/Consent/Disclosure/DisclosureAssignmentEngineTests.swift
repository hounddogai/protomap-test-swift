@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDisclosureAssignmentEngine()
        let item = Consent.newDisclosureAssignment("code-120", label: "label-278")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
