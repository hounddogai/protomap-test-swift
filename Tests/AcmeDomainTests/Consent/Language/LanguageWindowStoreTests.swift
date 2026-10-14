@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageWindowStore = Consent.newMemoryLanguageWindowStore()
        let item = Consent.newLanguageWindow("code-951", label: "label-48")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
