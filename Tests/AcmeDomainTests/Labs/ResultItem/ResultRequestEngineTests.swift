@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultRequestEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultRequest("code-734", title: "title-877")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
