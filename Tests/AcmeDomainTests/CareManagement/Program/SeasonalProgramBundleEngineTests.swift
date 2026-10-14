@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalProgramBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultSeasonalProgramBundleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newSeasonalProgramBundle("code-499", title: "title-626")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
