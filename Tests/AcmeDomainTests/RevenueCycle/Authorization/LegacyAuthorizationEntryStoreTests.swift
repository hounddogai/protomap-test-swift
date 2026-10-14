@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyAuthorizationEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyAuthorizationEntryStore = RevenueCycle.newMemoryLegacyAuthorizationEntryStore()
        let item = RevenueCycle.newLegacyAuthorizationEntry("code-710", label: "label-629")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
