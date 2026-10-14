@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackProxyThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackProxyThresholdStore = Consent.newMemoryFallbackProxyThresholdStore()
        let item = Consent.newFallbackProxyThreshold("code-952", name: "name-883")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
