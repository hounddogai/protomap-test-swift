@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictRevocationBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictRevocationBatchStore = Consent.newMemoryStrictRevocationBatchStore()
        let item = Consent.newStrictRevocationBatch("code-351", label: "label-454")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
