@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryTieredEligibilityTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.TieredEligibilityTemplateStore = Referrals.newMemoryTieredEligibilityTemplateStore()
        let item = Referrals.newTieredEligibilityTemplate("code-655", label: "label-117")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
