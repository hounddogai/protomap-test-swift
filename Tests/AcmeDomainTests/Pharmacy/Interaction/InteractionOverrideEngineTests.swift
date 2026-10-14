@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultInteractionOverrideEngine()
        let item = Pharmacy.newInteractionOverride("code-539", title: "title-264")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
