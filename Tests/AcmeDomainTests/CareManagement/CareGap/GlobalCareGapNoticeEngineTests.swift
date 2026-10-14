@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalCareGapNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGlobalCareGapNoticeEngine()
        let item = CareManagement.newGlobalCareGapNotice("code-694", name: "name-551")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
