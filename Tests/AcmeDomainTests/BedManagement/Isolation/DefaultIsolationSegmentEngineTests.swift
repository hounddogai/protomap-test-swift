@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultIsolationSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDefaultIsolationSegmentEngine()
        let item = BedManagement.newDefaultIsolationSegment("code-501", name: "name-65")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
