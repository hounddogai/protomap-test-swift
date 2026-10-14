@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientRemittanceAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientRemittanceAuditStore = RevenueCycle.newMemoryLenientRemittanceAuditStore()
        let item = RevenueCycle.newLenientRemittanceAudit("code-934", title: "title-62")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
