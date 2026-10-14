@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedStatementClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedStatementClaimStore = RevenueCycle.newMemoryCappedStatementClaimStore()
        let item = RevenueCycle.newCappedStatementClaim("code-125", name: "name-222")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
