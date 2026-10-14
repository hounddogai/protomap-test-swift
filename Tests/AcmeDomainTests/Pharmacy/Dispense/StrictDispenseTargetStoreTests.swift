@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictDispenseTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictDispenseTargetStore = Pharmacy.newMemoryStrictDispenseTargetStore()
        let item = Pharmacy.newStrictDispenseTarget("code-608", label: "label-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
