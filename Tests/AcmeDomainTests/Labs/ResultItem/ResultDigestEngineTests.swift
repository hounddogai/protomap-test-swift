@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultDigestEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultDigest("code-175", name: "name-314")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
