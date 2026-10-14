@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualProgramRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultManualProgramRollupEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newManualProgramRollup("code-294", name: "name-256")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
