@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceReviewStore = RevenueCycle.newMemoryRemittanceReviewStore()
        let item = RevenueCycle.newRemittanceReview("code-354", title: "title-68")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
