@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGlobalProgramPreferenceEngine()
        let item = CareManagement.newGlobalProgramPreference("code-974", title: "title-34")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
