@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientCensusTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLenientCensusTierEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLenientCensusTier("code-579", title: "title-668")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
