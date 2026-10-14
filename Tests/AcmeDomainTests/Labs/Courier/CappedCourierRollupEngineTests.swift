@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedCourierRollupEngine(Kit.Flags.newRegistry())
        let item = Labs.newCappedCourierRollup("code-134", name: "name-511")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
