@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryProxyBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryProxyBaselineStore = Consent.newMemoryPrimaryProxyBaselineStore()
        let item = Consent.newPrimaryProxyBaseline("code-765", name: "name-38")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
