@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalSubstitutionTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalSubstitutionTargetStore = Pharmacy.newMemorySeasonalSubstitutionTargetStore()
        let item = Pharmacy.newSeasonalSubstitutionTarget("code-153", label: "label-256")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
