@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimRecordStore = RevenueCycle.newMemoryClaimRecordStore()
        let item = RevenueCycle.newClaimRecord("code-593", name: "name-865")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
