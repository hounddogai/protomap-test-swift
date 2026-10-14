@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenQuotaStore = Labs.newMemorySpecimenQuotaStore()
        let item = Labs.newSpecimenQuota("code-557", name: "name-160")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
