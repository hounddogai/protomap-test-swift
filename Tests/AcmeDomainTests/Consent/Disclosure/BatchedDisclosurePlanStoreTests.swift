@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedDisclosurePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedDisclosurePlanStore = Consent.newMemoryBatchedDisclosurePlanStore()
        let item = Consent.newBatchedDisclosurePlan("code-815", title: "title-629")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
