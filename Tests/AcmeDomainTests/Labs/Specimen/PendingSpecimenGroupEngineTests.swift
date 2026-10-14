@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingSpecimenGroupEngine()
        let item = Labs.newPendingSpecimenGroup("code-764", label: "label-694")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
