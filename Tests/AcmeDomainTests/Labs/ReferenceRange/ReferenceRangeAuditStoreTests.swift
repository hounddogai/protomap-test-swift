@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeAuditStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeAuditStore = Labs.newMemoryReferenceRangeAuditStore()
        let item = Labs.newReferenceRangeAudit("code-656", name: "name-54")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
