@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLegacyCensusTierEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLegacyCensusTier("code-742", label: "label-29")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
