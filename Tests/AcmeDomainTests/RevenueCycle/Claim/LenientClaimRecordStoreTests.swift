@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientClaimRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientClaimRecordStore = RevenueCycle.newMemoryLenientClaimRecordStore()
        let item = RevenueCycle.newLenientClaimRecord("code-254", label: "label-250")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
