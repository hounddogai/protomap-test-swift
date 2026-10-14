@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCareGapProfileEngine()
        let item = CareManagement.newCareGapProfile("code-690", name: "name-619")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
