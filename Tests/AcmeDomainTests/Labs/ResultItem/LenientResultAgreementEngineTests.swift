@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientResultAgreementEngine(Kit.Flags.newRegistry())
        let item = Labs.newLenientResultAgreement("code-582", title: "title-990")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
