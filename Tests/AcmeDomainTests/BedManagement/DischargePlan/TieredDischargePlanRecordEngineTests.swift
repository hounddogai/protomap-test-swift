@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredDischargePlanRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTieredDischargePlanRecordEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newTieredDischargePlanRecord("code-466", label: "label-340")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
