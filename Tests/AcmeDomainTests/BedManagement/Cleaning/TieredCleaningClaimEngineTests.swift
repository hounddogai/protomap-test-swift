@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredCleaningClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTieredCleaningClaimEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newTieredCleaningClaim("code-453", label: "label-96")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
