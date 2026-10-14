@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryLanguageBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryLanguageBatchStore = Consent.newMemoryPrimaryLanguageBatchStore()
        let item = Consent.newPrimaryLanguageBatch("code-880", name: "name-504")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
