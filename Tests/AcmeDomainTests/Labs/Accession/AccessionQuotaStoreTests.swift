@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionQuotaStore = Labs.newMemoryAccessionQuotaStore()
        let item = Labs.newAccessionQuota("code-11", name: "name-491")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
