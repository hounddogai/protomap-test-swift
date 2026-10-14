@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPrimaryStatementRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PrimaryStatementRecordStore = RevenueCycle.newMemoryPrimaryStatementRecordStore()
        let item = RevenueCycle.newPrimaryStatementRecord("code-440", name: "name-697")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
