@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryTieredPanelAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.TieredPanelAuditStore = Labs.newMemoryTieredPanelAuditStore()
        let item = Labs.newTieredPanelAudit("code-681", name: "name-424")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
