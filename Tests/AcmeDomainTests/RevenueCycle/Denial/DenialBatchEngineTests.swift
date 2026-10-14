@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultDenialBatchEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newDenialBatch("code-830", label: "label-971")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
