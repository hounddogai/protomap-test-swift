@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierAgreementEngine()
        let item = Labs.newCourierAgreement("code-460", name: "name-492")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
