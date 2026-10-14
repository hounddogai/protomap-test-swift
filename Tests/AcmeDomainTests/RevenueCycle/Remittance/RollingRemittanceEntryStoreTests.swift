@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingRemittanceEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingRemittanceEntryStore = RevenueCycle.newMemoryRollingRemittanceEntryStore()
        let item = RevenueCycle.newRollingRemittanceEntry("code-227", name: "name-82")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
