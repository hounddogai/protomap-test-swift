@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierMappingEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierMapping("code-848", name: "name-653")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
