@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedProxyExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedProxyExceptionStore = Consent.newMemoryBatchedProxyExceptionStore()
        let item = Consent.newBatchedProxyException("code-51", title: "title-850")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
