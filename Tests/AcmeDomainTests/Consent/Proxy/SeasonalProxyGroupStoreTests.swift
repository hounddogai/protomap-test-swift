@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalProxyGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalProxyGroupStore = Consent.newMemorySeasonalProxyGroupStore()
        let item = Consent.newSeasonalProxyGroup("code-786", title: "title-713")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
