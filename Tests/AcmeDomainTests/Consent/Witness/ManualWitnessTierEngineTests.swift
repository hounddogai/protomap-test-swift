@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultManualWitnessTierEngine()
        let item = Consent.newManualWitnessTier("code-668", title: "title-892")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
