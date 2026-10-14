@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelScheduleEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelSchedule("code-920", label: "label-996")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
