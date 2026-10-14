@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingIsolationTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPendingIsolationTierEngine()
        let item = BedManagement.newPendingIsolationTier("code-344", label: "label-822")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
