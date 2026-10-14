@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultProgramSummaryEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newProgramSummary("code-362", title: "title-796")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
