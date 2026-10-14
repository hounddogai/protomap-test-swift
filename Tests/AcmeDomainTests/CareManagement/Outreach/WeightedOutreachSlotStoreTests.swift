@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryWeightedOutreachSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.WeightedOutreachSlotStore = CareManagement.newMemoryWeightedOutreachSlotStore()
        let item = CareManagement.newWeightedOutreachSlot("code-408", label: "label-407")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
