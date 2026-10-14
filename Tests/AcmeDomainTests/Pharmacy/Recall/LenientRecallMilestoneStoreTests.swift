@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientRecallMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientRecallMilestoneStore = Pharmacy.newMemoryLenientRecallMilestoneStore()
        let item = Pharmacy.newLenientRecallMilestone("code-920", label: "label-369")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
