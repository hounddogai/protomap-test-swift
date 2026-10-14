@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionRecordStore = Pharmacy.newMemorySubstitutionRecordStore()
        let item = Pharmacy.newSubstitutionRecord("code-676", name: "name-856")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
