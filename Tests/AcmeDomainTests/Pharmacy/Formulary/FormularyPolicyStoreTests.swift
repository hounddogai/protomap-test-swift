@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyPolicyStore = Pharmacy.newMemoryFormularyPolicyStore()
        let item = Pharmacy.newFormularyPolicy("code-976", label: "label-511")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
