@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingDenialEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingDenialEntryStore = RevenueCycle.newMemoryRollingDenialEntryStore()
        let item = RevenueCycle.newRollingDenialEntry("code-269", label: "label-234")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
