@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedRevocationMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWeightedRevocationMilestoneEngine(Kit.Flags.newRegistry())
        let item = Consent.newWeightedRevocationMilestone("code-567", title: "title-659")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
