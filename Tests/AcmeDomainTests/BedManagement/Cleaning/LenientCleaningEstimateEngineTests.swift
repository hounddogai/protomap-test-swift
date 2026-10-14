@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCleaningEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLenientCleaningEstimateEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLenientCleaningEstimate("code-685", name: "name-574")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
