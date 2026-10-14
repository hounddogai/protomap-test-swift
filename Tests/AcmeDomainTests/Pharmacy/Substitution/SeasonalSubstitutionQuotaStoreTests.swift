@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalSubstitutionQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalSubstitutionQuotaStore = Pharmacy.newMemorySeasonalSubstitutionQuotaStore()
        let item = Pharmacy.newSeasonalSubstitutionQuota("code-639", title: "title-254")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
