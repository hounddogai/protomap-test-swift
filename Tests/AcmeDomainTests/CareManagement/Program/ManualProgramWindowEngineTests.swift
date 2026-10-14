@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultManualProgramWindowEngine()
        let item = CareManagement.newManualProgramWindow("code-280", title: "title-503")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
