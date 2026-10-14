@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxySlotStore = Consent.newMemoryProxySlotStore()
        let item = Consent.newProxySlot("code-761", label: "label-787")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
