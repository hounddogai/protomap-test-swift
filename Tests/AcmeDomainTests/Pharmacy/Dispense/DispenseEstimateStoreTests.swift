@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseEstimateStore = Pharmacy.newMemoryDispenseEstimateStore()
        let item = Pharmacy.newDispenseEstimate("code-321", title: "title-748")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
