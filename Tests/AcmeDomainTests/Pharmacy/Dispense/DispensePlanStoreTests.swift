@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispensePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispensePlanStore = Pharmacy.newMemoryDispensePlanStore()
        let item = Pharmacy.newDispensePlan("code-465", title: "title-450")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
