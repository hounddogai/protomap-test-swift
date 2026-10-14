@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualRemittanceAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualRemittanceAdjustmentStore = RevenueCycle.newMemoryManualRemittanceAdjustmentStore()
        let item = RevenueCycle.newManualRemittanceAdjustment("code-791", name: "name-210")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
