@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledCourierTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultScheduledCourierTierEngine(Kit.Flags.newRegistry())
        let item = Labs.newScheduledCourierTier("code-342", title: "title-274")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
