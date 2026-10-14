@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageCycleStore = Consent.newMemoryLanguageCycleStore()
        let item = Consent.newLanguageCycle("code-873", label: "label-1")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
