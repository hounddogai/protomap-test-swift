@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosureTemplateEngine(Kit.Flags.newRegistry())
        let item = Referrals.newClosureTemplate("code-784", label: "label-682")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
