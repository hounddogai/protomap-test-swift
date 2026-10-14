@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingCourierWindowEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingCourierWindow("code-900", name: "name-253")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
