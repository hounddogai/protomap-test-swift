@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedBedBoardClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultWeightedBedBoardClaimEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newWeightedBedBoardClaim("code-163", name: "name-900")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
