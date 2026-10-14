@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedRevocationBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedRevocationBaselineStore = Consent.newMemoryBatchedRevocationBaselineStore()
        let item = Consent.newBatchedRevocationBaseline("code-228", title: "title-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
