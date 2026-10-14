@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultGlobalRevocationRecordEngine(Kit.Flags.newRegistry())
        let item = Consent.newGlobalRevocationRecord("code-413", title: "title-771")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
