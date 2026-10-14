@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementScoreStore = RevenueCycle.newMemoryStatementScoreStore()
        let item = RevenueCycle.newStatementScore("code-910", label: "label-947")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
