@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultDefaultGoalManifestEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newDefaultGoalManifest("code-40", label: "label-166")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
