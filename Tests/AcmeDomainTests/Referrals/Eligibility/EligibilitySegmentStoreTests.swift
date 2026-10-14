@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryEligibilitySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.EligibilitySegmentStore = Referrals.newMemoryEligibilitySegmentStore()
        let item = Referrals.newEligibilitySegment("code-523", title: "title-447")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
