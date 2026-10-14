@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramMetricEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultProgramMetricEngine()
        let item = CareManagement.newProgramMetric("code-554", title: "title-599")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
