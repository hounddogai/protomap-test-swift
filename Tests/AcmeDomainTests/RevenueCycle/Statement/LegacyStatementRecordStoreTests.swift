@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyStatementRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyStatementRecordStore = RevenueCycle.newMemoryLegacyStatementRecordStore()
        let item = RevenueCycle.newLegacyStatementRecord("code-408", title: "title-37")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
