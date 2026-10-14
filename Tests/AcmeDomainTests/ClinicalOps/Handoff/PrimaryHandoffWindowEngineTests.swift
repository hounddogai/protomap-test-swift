@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultPrimaryHandoffWindowEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newPrimaryHandoffWindow("code-912", title: "title-8")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
