@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryNetworkTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.NetworkTemplateStore = Referrals.newMemoryNetworkTemplateStore()
        let item = Referrals.newNetworkTemplate("code-420", label: "label-562")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
