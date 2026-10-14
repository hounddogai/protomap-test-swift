@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultChargeRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultChargeRequestStore = RevenueCycle.newMemoryDefaultChargeRequestStore()
        let item = RevenueCycle.newDefaultChargeRequest("code-530", name: "name-484")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
