@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyStatementExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyStatementExceptionStore = RevenueCycle.newMemoryLegacyStatementExceptionStore()
        let item = RevenueCycle.newLegacyStatementException("code-940", title: "title-834")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
