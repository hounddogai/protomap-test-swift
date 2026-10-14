@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeWindowStore = RevenueCycle.newMemoryChargeWindowStore()
        let item = RevenueCycle.newChargeWindow("code-483", title: "title-947")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
