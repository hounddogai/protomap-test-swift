@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalCensusCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultGlobalCensusCheckpointEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newGlobalCensusCheckpoint("code-794", title: "title-550")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
