@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultClaimTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultClaimTargetStore = RevenueCycle.newMemoryDefaultClaimTargetStore()
        let item = RevenueCycle.newDefaultClaimTarget("code-204", title: "title-470")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
