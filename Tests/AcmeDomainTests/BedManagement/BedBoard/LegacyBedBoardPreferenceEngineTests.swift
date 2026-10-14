@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyBedBoardPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLegacyBedBoardPreferenceEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLegacyBedBoardPreference("code-573", label: "label-612")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
