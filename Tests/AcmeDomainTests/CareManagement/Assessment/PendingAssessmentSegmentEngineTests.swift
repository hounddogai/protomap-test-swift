@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPendingAssessmentSegmentEngine()
        let item = CareManagement.newPendingAssessmentSegment("code-160", name: "name-320")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
