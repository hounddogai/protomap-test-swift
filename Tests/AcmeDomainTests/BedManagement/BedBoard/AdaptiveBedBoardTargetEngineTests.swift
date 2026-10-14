@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultAdaptiveBedBoardTargetEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newAdaptiveBedBoardTarget("code-375", title: "title-319")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
