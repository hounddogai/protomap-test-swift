@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedRevocationDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedRevocationDigestStore = Consent.newMemoryBatchedRevocationDigestStore()
        let item = Consent.newBatchedRevocationDigest("code-777", label: "label-993")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
