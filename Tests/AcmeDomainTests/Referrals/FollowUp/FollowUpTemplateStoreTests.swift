@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryFollowUpTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.FollowUpTemplateStore = Referrals.newMemoryFollowUpTemplateStore()
        let item = Referrals.newFollowUpTemplate("code-950", label: "label-935")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
