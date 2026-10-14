@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalDischargePlanProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRegionalDischargePlanProfileEngine()
        let item = BedManagement.newRegionalDischargePlanProfile("code-925", title: "title-428")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
