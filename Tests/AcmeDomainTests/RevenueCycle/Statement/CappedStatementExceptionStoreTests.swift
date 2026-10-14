@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedStatementExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedStatementExceptionStore = RevenueCycle.newMemoryCappedStatementExceptionStore()
        let item = RevenueCycle.newCappedStatementException("code-493", label: "label-825")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
