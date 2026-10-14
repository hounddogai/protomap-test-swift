@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingRemittanceMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingRemittanceMappingStore = RevenueCycle.newMemoryPendingRemittanceMappingStore()
        let item = RevenueCycle.newPendingRemittanceMapping("code-541", title: "title-37")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
