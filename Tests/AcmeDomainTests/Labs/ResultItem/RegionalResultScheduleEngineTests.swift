@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalResultScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRegionalResultScheduleEngine(Kit.Flags.newRegistry())
        let item = Labs.newRegionalResultSchedule("code-377", name: "name-507")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
