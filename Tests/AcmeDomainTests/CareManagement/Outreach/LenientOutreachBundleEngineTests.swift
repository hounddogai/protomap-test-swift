@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLenientOutreachBundleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newLenientOutreachBundle("code-20", name: "name-716")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
