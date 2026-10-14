@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRollingProgramDraftEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRollingProgramDraft("code-199", name: "name-825")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
