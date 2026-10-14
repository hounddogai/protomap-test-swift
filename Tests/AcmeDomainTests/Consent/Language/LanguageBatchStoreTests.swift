@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageBatchStore = Consent.newMemoryLanguageBatchStore()
        let item = Consent.newLanguageBatch("code-786", title: "title-434")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
