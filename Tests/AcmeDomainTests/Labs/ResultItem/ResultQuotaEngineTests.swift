@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultQuotaEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultQuota("code-32", label: "label-594")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
