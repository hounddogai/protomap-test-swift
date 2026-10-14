@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultScheduledHandoffWindowEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newScheduledHandoffWindow("code-818", label: "label-367")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
