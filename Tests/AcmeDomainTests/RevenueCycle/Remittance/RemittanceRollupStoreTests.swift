@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceRollupStore = RevenueCycle.newMemoryRemittanceRollupStore()
        let item = RevenueCycle.newRemittanceRollup("code-301", name: "name-414")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
