@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedDisclosureRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedDisclosureRequestStore = Consent.newMemoryBatchedDisclosureRequestStore()
        let item = Consent.newBatchedDisclosureRequest("code-166", title: "title-322")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
