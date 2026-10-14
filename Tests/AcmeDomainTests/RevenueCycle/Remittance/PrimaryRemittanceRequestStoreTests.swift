@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryRemittanceRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryRemittanceRequestStore = RevenueCycle.newMemoryPrimaryRemittanceRequestStore()
        let item = RevenueCycle.newPrimaryRemittanceRequest("code-44", title: "title-156")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
