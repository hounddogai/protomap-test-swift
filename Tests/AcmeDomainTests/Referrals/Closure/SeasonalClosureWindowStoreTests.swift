@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemorySeasonalClosureWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.SeasonalClosureWindowStore = Referrals.newMemorySeasonalClosureWindowStore()
        let item = Referrals.newSeasonalClosureWindow("code-495", label: "label-14")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
