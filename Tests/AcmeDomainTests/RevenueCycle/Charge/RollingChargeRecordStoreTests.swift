@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingChargeRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingChargeRecordStore = RevenueCycle.newMemoryRollingChargeRecordStore()
        let item = RevenueCycle.newRollingChargeRecord("code-631", name: "name-803")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
