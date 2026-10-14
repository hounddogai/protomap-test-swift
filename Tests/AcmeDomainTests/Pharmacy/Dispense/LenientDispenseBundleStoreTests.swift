@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientDispenseBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientDispenseBundleStore = Pharmacy.newMemoryLenientDispenseBundleStore()
        let item = Pharmacy.newLenientDispenseBundle("code-40", name: "name-620")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
