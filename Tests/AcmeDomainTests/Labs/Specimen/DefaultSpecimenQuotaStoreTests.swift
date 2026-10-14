@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultSpecimenQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultSpecimenQuotaStore = Labs.newMemoryDefaultSpecimenQuotaStore()
        let item = Labs.newDefaultSpecimenQuota("code-126", label: "label-174")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
