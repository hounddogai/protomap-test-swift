@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRegionalOutreachSegmentEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRegionalOutreachSegment("code-898", title: "title-343")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
