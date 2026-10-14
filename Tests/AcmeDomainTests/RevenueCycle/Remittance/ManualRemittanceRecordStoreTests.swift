@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualRemittanceRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualRemittanceRecordStore = RevenueCycle.newMemoryManualRemittanceRecordStore()
        let item = RevenueCycle.newManualRemittanceRecord("code-985", name: "name-410")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
