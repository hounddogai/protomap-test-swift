@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryAcuityPlanSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPrimaryAcuityPlanSnapshotEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPrimaryAcuityPlanSnapshot("code-883", label: "label-515")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
