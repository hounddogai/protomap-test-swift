@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingSpecimenCycleEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingSpecimenCycle("code-604", label: "label-545")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
