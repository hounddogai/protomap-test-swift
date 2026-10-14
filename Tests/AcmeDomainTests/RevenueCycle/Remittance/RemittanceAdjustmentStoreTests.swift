@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceAdjustmentStore = RevenueCycle.newMemoryRemittanceAdjustmentStore()
        let item = RevenueCycle.newRemittanceAdjustment("code-16", label: "label-356")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
