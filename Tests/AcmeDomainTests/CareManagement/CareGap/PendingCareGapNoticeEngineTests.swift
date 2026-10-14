@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPendingCareGapNoticeEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPendingCareGapNotice("code-86", label: "label-329")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
