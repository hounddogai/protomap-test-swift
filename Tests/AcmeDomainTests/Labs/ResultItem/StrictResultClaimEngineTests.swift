@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictResultClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultStrictResultClaimEngine(Kit.Flags.newRegistry())
        let item = Labs.newStrictResultClaim("code-682", name: "name-71")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
