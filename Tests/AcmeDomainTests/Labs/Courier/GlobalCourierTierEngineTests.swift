@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalCourierTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultGlobalCourierTierEngine(Kit.Flags.newRegistry())
        let item = Labs.newGlobalCourierTier("code-892", title: "title-597")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
