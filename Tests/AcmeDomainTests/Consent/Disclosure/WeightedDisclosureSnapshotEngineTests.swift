@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedDisclosureSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWeightedDisclosureSnapshotEngine(Kit.Flags.newRegistry())
        let item = Consent.newWeightedDisclosureSnapshot("code-834", label: "label-654")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
