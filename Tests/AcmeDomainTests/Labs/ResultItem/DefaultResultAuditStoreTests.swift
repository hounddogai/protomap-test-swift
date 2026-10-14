@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultResultAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultResultAuditStore = Labs.newMemoryDefaultResultAuditStore()
        let item = Labs.newDefaultResultAudit("code-726", title: "title-105")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
