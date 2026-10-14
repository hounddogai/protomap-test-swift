@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientProxyClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientProxyClaimStore = Consent.newMemoryLenientProxyClaimStore()
        let item = Consent.newLenientProxyClaim("code-51", name: "name-262")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
