@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictTransferScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultStrictTransferScoreEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newStrictTransferScore("code-604", label: "label-553")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
