@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultManualBedBoardWindowEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newManualBedBoardWindow("code-349", label: "label-237")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
