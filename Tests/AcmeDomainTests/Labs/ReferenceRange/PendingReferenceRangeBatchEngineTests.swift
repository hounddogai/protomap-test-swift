@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingReferenceRangeBatchEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingReferenceRangeBatch("code-912", title: "title-701")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
