@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultQuotaStore = Labs.newMemoryResultQuotaStore()
        let item = Labs.newResultQuota("code-32", label: "label-594")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
