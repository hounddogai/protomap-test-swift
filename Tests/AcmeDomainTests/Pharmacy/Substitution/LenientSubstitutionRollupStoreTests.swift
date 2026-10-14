@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientSubstitutionRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientSubstitutionRollupStore = Pharmacy.newMemoryLenientSubstitutionRollupStore()
        let item = Pharmacy.newLenientSubstitutionRollup("code-6", label: "label-469")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
