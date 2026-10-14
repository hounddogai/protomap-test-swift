@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryStrictClosureSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.StrictClosureSegmentStore = Referrals.newMemoryStrictClosureSegmentStore()
        let item = Referrals.newStrictClosureSegment("code-260", name: "name-429")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
