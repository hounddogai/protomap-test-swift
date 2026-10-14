@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalCleaningManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultSeasonalCleaningManifestEngine()
        let item = BedManagement.newSeasonalCleaningManifest("code-229", name: "name-788")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
