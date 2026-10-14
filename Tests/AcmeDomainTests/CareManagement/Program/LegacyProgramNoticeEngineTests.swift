@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyProgramNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLegacyProgramNoticeEngine()
        let item = CareManagement.newLegacyProgramNotice("code-493", label: "label-671")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
