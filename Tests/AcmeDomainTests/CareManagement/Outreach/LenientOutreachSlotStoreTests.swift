@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientOutreachSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientOutreachSlotStore = CareManagement.newMemoryLenientOutreachSlotStore()
        let item = CareManagement.newLenientOutreachSlot("code-853", title: "title-186")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
