@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryTieredSubstitutionProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.TieredSubstitutionProfileStore = Pharmacy.newMemoryTieredSubstitutionProfileStore()
        let item = Pharmacy.newTieredSubstitutionProfile("code-853", label: "label-811")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
