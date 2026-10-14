@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultProgramSnapshotEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newProgramSnapshot("code-229", label: "label-668")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
