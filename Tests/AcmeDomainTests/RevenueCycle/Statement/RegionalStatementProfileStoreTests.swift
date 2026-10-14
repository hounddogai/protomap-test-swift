@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRegionalStatementProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RegionalStatementProfileStore = RevenueCycle.newMemoryRegionalStatementProfileStore()
        let item = RevenueCycle.newRegionalStatementProfile("code-74", title: "title-602")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
