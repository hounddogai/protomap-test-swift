@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryDenialScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryDenialScoreStore = RevenueCycle.newMemoryPrimaryDenialScoreStore()
        let item = RevenueCycle.newPrimaryDenialScore("code-954", name: "name-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
