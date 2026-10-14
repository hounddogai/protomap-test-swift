@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseTierStore = Pharmacy.newMemoryDispenseTierStore()
        let item = Pharmacy.newDispenseTier("code-940", name: "name-413")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
