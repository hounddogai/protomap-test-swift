@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedSpecimenQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedSpecimenQuotaStore = Labs.newMemoryCappedSpecimenQuotaStore()
        let item = Labs.newCappedSpecimenQuota("code-310", label: "label-298")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
