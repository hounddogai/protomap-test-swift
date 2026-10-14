@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementSlotStore = RevenueCycle.newMemoryStatementSlotStore()
        let item = RevenueCycle.newStatementSlot("code-712", label: "label-958")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
