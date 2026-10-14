@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierPolicyEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierPolicy("code-675", name: "name-96")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
