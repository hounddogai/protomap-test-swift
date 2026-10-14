@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTransferThresholdEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newTransferThreshold("code-876", name: "name-956")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
