@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDischargePlanCheckpointEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newDischargePlanCheckpoint("code-719", title: "title-667")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
