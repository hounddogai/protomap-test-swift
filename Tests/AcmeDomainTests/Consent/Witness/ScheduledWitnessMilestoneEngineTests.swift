@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledWitnessMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultScheduledWitnessMilestoneEngine(Kit.Flags.newRegistry())
        let item = Consent.newScheduledWitnessMilestone("code-874", title: "title-355")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
