@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualOutreachSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualOutreachSlotStore = CareManagement.newMemoryManualOutreachSlotStore()
        let item = CareManagement.newManualOutreachSlot("code-92", name: "name-126")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
