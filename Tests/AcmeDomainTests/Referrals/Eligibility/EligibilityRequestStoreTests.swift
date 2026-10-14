@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityRequestStore = Referrals.newMemoryEligibilityRequestStore()
        let item = Referrals.newEligibilityRequest("code-662", title: "title-516")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
