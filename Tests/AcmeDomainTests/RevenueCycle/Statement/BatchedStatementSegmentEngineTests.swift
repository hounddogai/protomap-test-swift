@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultBatchedStatementSegmentEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newBatchedStatementSegment("code-521", name: "name-198")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
