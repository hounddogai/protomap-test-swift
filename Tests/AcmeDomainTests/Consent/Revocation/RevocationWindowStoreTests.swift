@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationWindowStore = Consent.newMemoryRevocationWindowStore()
        let item = Consent.newRevocationWindow("code-790", title: "title-997")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
