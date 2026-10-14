@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRegionalProxyQuotaEngine(Kit.Flags.newRegistry())
        let item = Consent.newRegionalProxyQuota("code-364", name: "name-910")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
