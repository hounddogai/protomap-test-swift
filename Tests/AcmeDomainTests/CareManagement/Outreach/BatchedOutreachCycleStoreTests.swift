@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedOutreachCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedOutreachCycleStore = CareManagement.newMemoryBatchedOutreachCycleStore()
        let item = CareManagement.newBatchedOutreachCycle("code-377", title: "title-599")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
