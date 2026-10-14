@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultGlobalDisclosureSnapshotEngine(Kit.Flags.newRegistry())
        let item = Consent.newGlobalDisclosureSnapshot("code-218", label: "label-216")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
