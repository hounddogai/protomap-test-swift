@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackStatementNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultFallbackStatementNoticeEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newFallbackStatementNotice("code-149", title: "title-422")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
