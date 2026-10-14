@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalSpecimenQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalSpecimenQuotaStore = Labs.newMemorySeasonalSpecimenQuotaStore()
        let item = Labs.newSeasonalSpecimenQuota("code-980", label: "label-498")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
