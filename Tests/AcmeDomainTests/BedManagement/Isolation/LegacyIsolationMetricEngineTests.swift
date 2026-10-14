@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLegacyIsolationMetricEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLegacyIsolationMetric("code-547", name: "name-94")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
