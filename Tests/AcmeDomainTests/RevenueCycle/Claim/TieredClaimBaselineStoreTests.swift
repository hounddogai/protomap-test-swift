@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredClaimBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredClaimBaselineStore = RevenueCycle.newMemoryTieredClaimBaselineStore()
        let item = RevenueCycle.newTieredClaimBaseline("code-732", label: "label-465")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
