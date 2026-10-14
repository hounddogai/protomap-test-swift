@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultRecallMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultRecallMilestoneStore = Pharmacy.newMemoryDefaultRecallMilestoneStore()
        let item = Pharmacy.newDefaultRecallMilestone("code-877", title: "title-553")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
