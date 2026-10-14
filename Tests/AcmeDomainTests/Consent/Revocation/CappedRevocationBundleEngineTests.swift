@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedRevocationBundleEngine()
        let item = Consent.newCappedRevocationBundle("code-296", name: "name-625")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
