@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultDispenseExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultDispenseExceptionStore = Pharmacy.newMemoryDefaultDispenseExceptionStore()
        let item = Pharmacy.newDefaultDispenseException("code-762", name: "name-648")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
