@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultAssessmentEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultDefaultAssessmentEntryEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newDefaultAssessmentEntry("code-606", name: "name-730")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
