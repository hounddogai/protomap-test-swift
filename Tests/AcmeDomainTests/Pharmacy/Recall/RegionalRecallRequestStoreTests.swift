@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalRecallRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalRecallRequestStore = Pharmacy.newMemoryRegionalRecallRequestStore()
        let item = Pharmacy.newRegionalRecallRequest("code-460", title: "title-110")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
