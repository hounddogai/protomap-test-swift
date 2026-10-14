@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryScheduledFollowUpManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ScheduledFollowUpManifestStore = Referrals.newMemoryScheduledFollowUpManifestStore()
        let item = Referrals.newScheduledFollowUpManifest("code-550", title: "title-523")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
