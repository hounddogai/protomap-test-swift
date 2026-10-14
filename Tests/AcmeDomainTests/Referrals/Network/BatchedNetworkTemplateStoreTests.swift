@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryBatchedNetworkTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.BatchedNetworkTemplateStore = Referrals.newMemoryBatchedNetworkTemplateStore()
        let item = Referrals.newBatchedNetworkTemplate("code-277", label: "label-452")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
