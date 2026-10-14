@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyAuditEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxyAudit("code-870", title: "title-510")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
