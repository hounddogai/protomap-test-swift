@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictFormularyPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictFormularyPolicyStore = Pharmacy.newMemoryStrictFormularyPolicyStore()
        let item = Pharmacy.newStrictFormularyPolicy("code-111", label: "label-820")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
