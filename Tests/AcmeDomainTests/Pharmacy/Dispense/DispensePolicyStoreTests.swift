@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispensePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispensePolicyStore = Pharmacy.newMemoryDispensePolicyStore()
        let item = Pharmacy.newDispensePolicy("code-99", label: "label-638")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
