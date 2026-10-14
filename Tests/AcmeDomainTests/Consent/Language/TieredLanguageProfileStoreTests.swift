@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredLanguageProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredLanguageProfileStore = Consent.newMemoryTieredLanguageProfileStore()
        let item = Consent.newTieredLanguageProfile("code-870", title: "title-753")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
