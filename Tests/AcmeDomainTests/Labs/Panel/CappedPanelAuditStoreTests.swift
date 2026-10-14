@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedPanelAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedPanelAuditStore = Labs.newMemoryCappedPanelAuditStore()
        let item = Labs.newCappedPanelAudit("code-250", name: "name-817")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
