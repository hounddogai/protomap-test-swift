@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementExceptionStore = RevenueCycle.newMemoryStatementExceptionStore()
        let item = RevenueCycle.newStatementException("code-664", label: "label-947")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
