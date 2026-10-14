@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientChargeTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientChargeTierStore = RevenueCycle.newMemoryLenientChargeTierStore()
        let item = RevenueCycle.newLenientChargeTier("code-655", label: "label-258")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
