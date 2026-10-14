@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceEntryStore = RevenueCycle.newMemoryRemittanceEntryStore()
        let item = RevenueCycle.newRemittanceEntry("code-81", name: "name-149")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
