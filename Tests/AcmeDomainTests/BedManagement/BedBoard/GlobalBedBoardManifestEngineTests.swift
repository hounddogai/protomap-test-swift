@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalBedBoardManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultGlobalBedBoardManifestEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newGlobalBedBoardManifest("code-586", label: "label-940")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
