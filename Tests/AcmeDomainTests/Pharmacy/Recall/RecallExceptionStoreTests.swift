@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallExceptionStore = Pharmacy.newMemoryRecallExceptionStore()
        let item = Pharmacy.newRecallException("code-737", name: "name-769")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
