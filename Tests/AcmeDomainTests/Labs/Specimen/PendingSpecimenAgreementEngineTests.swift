@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingSpecimenAgreementEngine()
        let item = Labs.newPendingSpecimenAgreement("code-151", label: "label-350")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
