@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceBaselineStore = RevenueCycle.newMemoryRemittanceBaselineStore()
        let item = RevenueCycle.newRemittanceBaseline("code-804", title: "title-203")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
