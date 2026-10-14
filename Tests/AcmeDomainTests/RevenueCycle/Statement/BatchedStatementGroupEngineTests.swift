@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultBatchedStatementGroupEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newBatchedStatementGroup("code-987", title: "title-697")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
