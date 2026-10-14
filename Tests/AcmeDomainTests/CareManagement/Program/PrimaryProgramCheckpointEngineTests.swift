@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryProgramCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPrimaryProgramCheckpointEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPrimaryProgramCheckpoint("code-683", title: "title-882")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
