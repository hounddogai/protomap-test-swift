@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyAllocationStore = Consent.newMemoryProxyAllocationStore()
        let item = Consent.newProxyAllocation("code-92", name: "name-649")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
