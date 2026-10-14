@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxySlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxySlotEngine()
        let item = Consent.newProxySlot("code-761", label: "label-787")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
