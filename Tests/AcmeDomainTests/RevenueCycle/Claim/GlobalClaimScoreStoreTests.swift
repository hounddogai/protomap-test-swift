@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryGlobalClaimScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.GlobalClaimScoreStore = RevenueCycle.newMemoryGlobalClaimScoreStore()
        let item = RevenueCycle.newGlobalClaimScore("code-512", name: "name-690")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
