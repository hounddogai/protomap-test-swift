@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryRemittanceVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryRemittanceVarianceStore = RevenueCycle.newMemoryPrimaryRemittanceVarianceStore()
        let item = RevenueCycle.newPrimaryRemittanceVariance("code-430", title: "title-576")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
