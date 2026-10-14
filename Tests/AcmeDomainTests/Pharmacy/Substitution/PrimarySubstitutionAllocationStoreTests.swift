@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimarySubstitutionAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimarySubstitutionAllocationStore = Pharmacy.newMemoryPrimarySubstitutionAllocationStore()
        let item = Pharmacy.newPrimarySubstitutionAllocation("code-980", name: "name-294")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
