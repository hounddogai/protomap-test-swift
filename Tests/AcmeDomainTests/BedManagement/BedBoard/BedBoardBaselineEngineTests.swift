@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBedBoardBaselineEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBedBoardBaseline("code-964", label: "label-888")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
