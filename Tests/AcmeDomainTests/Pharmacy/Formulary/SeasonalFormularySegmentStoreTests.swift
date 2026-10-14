@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalFormularySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalFormularySegmentStore = Pharmacy.newMemorySeasonalFormularySegmentStore()
        let item = Pharmacy.newSeasonalFormularySegment("code-175", label: "label-424")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
