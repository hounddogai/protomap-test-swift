@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedRecallProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultBatchedRecallProfileEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newBatchedRecallProfile("code-583", label: "label-317")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
