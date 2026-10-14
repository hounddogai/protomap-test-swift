@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelQuotaEngine()
        let item = Labs.newPanelQuota("code-896", title: "title-768")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
