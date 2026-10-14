@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPrimaryReferenceRangeScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPrimaryReferenceRangeScheduleEngine()
        let item = Labs.newPrimaryReferenceRangeSchedule("code-926", title: "title-277")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
