@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedProxySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedProxySlotStore = Consent.newMemoryBatchedProxySlotStore()
        let item = Consent.newBatchedProxySlot("code-657", label: "label-419")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
