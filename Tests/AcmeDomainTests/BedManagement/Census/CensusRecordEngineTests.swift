@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCensusRecordEngine()
        let item = BedManagement.newCensusRecord("code-527", label: "label-960")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
