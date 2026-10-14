@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionAuditStore = Labs.newMemoryAccessionAuditStore()
        let item = Labs.newAccessionAudit("code-814", label: "label-881")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
