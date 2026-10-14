@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceProfileStore = RevenueCycle.newMemoryRemittanceProfileStore()
        let item = RevenueCycle.newRemittanceProfile("code-92", name: "name-539")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
