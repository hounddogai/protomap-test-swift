@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultWeightedTransferTargetEngine()
        let item = BedManagement.newWeightedTransferTarget("code-220", label: "label-789")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
