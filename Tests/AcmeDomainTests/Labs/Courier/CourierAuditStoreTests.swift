@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierAuditStore = Labs.newMemoryCourierAuditStore()
        let item = Labs.newCourierAudit("code-948", title: "title-3")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
