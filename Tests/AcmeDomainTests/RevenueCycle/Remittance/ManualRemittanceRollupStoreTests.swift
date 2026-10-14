@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualRemittanceRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualRemittanceRollupStore = RevenueCycle.newMemoryManualRemittanceRollupStore()
        let item = RevenueCycle.newManualRemittanceRollup("code-780", name: "name-550")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
