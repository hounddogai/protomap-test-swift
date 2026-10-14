@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageTierStore = Consent.newMemoryLanguageTierStore()
        let item = Consent.newLanguageTier("code-475", title: "title-949")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
