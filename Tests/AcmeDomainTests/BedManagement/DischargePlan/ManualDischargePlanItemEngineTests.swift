@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualDischargePlanItemEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultManualDischargePlanItemEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newManualDischargePlanItem("code-8", title: "title-391")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
