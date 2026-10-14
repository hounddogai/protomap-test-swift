@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageEntryStore = Consent.newMemoryLanguageEntryStore()
        let item = Consent.newLanguageEntry("code-841", label: "label-528")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
