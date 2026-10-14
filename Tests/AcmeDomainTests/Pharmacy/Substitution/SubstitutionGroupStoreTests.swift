@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionGroupStore = Pharmacy.newMemorySubstitutionGroupStore()
        let item = Pharmacy.newSubstitutionGroup("code-803", name: "name-143")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
