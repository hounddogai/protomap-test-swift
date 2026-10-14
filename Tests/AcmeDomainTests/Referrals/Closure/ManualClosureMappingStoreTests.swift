@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsMemoryManualClosureMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Referrals.ManualClosureMappingStore = Referrals.newMemoryManualClosureMappingStore()
        let item = Referrals.newManualClosureMapping("code-725", title: "title-569")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
