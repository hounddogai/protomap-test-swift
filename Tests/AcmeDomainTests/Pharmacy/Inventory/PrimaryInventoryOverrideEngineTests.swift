@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPrimaryInventoryOverrideEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPrimaryInventoryOverride("code-786", title: "title-999")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
