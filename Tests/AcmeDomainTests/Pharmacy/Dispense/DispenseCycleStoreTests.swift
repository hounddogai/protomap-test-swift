@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseCycleStore = Pharmacy.newMemoryDispenseCycleStore()
        let item = Pharmacy.newDispenseCycle("code-179", title: "title-530")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
