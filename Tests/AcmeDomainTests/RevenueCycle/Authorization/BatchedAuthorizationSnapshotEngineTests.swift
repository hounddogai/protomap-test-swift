@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultBatchedAuthorizationSnapshotEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("code-442", title: "title-327")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
