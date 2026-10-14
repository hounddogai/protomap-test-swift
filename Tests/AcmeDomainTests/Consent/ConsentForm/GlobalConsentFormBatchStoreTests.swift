@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalConsentFormBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalConsentFormBatchStore = Consent.newMemoryGlobalConsentFormBatchStore()
        let item = Consent.newGlobalConsentFormBatch("code-521", name: "name-541")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
