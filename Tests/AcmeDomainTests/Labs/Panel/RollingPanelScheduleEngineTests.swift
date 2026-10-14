@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingPanelScheduleEngine(Kit.Flags.newRegistry())
        let item = Labs.newRollingPanelSchedule("code-175", label: "label-865")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
