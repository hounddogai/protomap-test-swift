@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredRemittanceRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredRemittanceRecordStore = RevenueCycle.newMemoryTieredRemittanceRecordStore()
        let item = RevenueCycle.newTieredRemittanceRecord("code-411", name: "name-4")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
