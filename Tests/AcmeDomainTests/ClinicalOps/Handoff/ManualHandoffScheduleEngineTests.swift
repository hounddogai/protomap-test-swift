@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualHandoffScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultManualHandoffScheduleEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newManualHandoffSchedule("code-204", label: "label-928")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
