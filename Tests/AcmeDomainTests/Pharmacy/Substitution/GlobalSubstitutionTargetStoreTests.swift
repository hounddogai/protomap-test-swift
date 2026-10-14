@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalSubstitutionTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalSubstitutionTargetStore = Pharmacy.newMemoryGlobalSubstitutionTargetStore()
        let item = Pharmacy.newGlobalSubstitutionTarget("code-617", name: "name-203")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
