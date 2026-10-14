@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalProxyBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalProxyBaselineStore = Consent.newMemoryRegionalProxyBaselineStore()
        let item = Consent.newRegionalProxyBaseline("code-640", name: "name-506")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
