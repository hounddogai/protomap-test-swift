@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedRoundingScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultCappedRoundingScheduleEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newCappedRoundingSchedule("code-572", label: "label-419")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
