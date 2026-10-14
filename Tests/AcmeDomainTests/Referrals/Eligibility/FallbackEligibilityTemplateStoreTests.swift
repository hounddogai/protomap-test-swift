@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFallbackEligibilityTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FallbackEligibilityTemplateStore = Referrals.newMemoryFallbackEligibilityTemplateStore()
        let item = Referrals.newFallbackEligibilityTemplate("code-15", label: "label-494")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
