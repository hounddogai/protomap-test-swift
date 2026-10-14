@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalInteractionAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalInteractionAgreementStore = Pharmacy.newMemorySeasonalInteractionAgreementStore()
        let item = Pharmacy.newSeasonalInteractionAgreement("code-160", label: "label-493")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
