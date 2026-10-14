@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyRecordStore = Consent.newMemoryProxyRecordStore()
        let item = Consent.newProxyRecord("code-440", name: "name-274")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
