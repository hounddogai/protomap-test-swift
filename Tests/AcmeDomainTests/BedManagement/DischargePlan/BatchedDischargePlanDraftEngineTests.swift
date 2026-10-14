@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedDischargePlanDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultBatchedDischargePlanDraftEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newBatchedDischargePlanDraft("code-521", name: "name-944")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
