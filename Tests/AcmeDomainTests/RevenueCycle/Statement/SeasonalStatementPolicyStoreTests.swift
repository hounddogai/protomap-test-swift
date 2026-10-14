@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemorySeasonalStatementPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.SeasonalStatementPolicyStore = RevenueCycle.newMemorySeasonalStatementPolicyStore()
        let item = RevenueCycle.newSeasonalStatementPolicy("code-741", name: "name-89")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
