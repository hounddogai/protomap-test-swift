@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageAdjustmentStore = Consent.newMemoryLanguageAdjustmentStore()
        let item = Consent.newLanguageAdjustment("code-229", name: "name-558")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
