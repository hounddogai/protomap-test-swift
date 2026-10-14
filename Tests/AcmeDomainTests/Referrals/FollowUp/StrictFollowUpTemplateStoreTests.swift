@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictFollowUpTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictFollowUpTemplateStore = Referrals.newMemoryStrictFollowUpTemplateStore()
        let item = Referrals.newStrictFollowUpTemplate("code-307", label: "label-15")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
