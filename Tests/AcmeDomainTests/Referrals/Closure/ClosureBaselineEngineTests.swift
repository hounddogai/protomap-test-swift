@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosureBaselineEngine(Kit.Flags.newRegistry())
        let item = Referrals.newClosureBaseline("code-303", label: "label-518")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
