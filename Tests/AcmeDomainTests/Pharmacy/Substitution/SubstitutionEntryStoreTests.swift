@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionEntryStore = Pharmacy.newMemorySubstitutionEntryStore()
        let item = Pharmacy.newSubstitutionEntry("code-576", label: "label-193")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
