@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseBatchStore = Pharmacy.newMemoryDispenseBatchStore()
        let item = Pharmacy.newDispenseBatch("code-125", title: "title-881")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
