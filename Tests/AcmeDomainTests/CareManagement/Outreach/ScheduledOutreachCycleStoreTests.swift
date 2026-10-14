@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledOutreachCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledOutreachCycleStore = CareManagement.newMemoryScheduledOutreachCycleStore()
        let item = CareManagement.newScheduledOutreachCycle("code-164", label: "label-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
