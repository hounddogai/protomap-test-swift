@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedDisclosureSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedDisclosureSegmentStore = Consent.newMemoryBatchedDisclosureSegmentStore()
        let item = Consent.newBatchedDisclosureSegment("code-33", name: "name-549")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
