@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementReviewStore = RevenueCycle.newMemoryStatementReviewStore()
        let item = RevenueCycle.newStatementReview("code-663", name: "name-524")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
