@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCensusDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultAdaptiveCensusDraftEngine()
        let item = BedManagement.newAdaptiveCensusDraft("code-151", label: "label-436")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
