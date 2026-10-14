@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientDispenseOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientDispenseOverrideStore = Pharmacy.newMemoryLenientDispenseOverrideStore()
        let item = Pharmacy.newLenientDispenseOverride("code-985", title: "title-395")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
