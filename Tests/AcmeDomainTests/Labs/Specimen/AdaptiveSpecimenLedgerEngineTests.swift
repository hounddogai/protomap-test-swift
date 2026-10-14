@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAdaptiveSpecimenLedgerEngine()
        let item = Labs.newAdaptiveSpecimenLedger("code-112", label: "label-452")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
