@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBatchedIsolationRollupEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBatchedIsolationRollup("code-530", title: "title-483")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
