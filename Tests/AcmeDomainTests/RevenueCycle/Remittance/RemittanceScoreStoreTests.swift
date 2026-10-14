@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceScoreStore = RevenueCycle.newMemoryRemittanceScoreStore()
        let item = RevenueCycle.newRemittanceScore("code-492", name: "name-334")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
