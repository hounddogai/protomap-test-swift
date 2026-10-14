@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRegionalAssessmentNoticeEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRegionalAssessmentNotice("code-189", label: "label-231")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
