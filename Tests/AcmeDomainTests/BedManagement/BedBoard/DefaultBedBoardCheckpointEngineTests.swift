@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDefaultBedBoardCheckpointEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newDefaultBedBoardCheckpoint("code-415", name: "name-897")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
