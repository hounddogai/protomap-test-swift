@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacySpecimenProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLegacySpecimenProfileEngine(Kit.Flags.newRegistry())
        let item = Labs.newLegacySpecimenProfile("code-51", label: "label-688")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
