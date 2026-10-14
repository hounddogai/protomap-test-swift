@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualSpecimenOverrideEngine()
        let item = Labs.newManualSpecimenOverride("code-118", label: "label-988")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
