@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilityWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilityWindowStore = Referrals.newMemoryEligibilityWindowStore()
        let item = Referrals.newEligibilityWindow("code-121", label: "label-884")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
