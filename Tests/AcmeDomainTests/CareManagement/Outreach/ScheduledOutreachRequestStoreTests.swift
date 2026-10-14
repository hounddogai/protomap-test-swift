@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledOutreachRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledOutreachRequestStore = CareManagement.newMemoryScheduledOutreachRequestStore()
        let item = CareManagement.newScheduledOutreachRequest("code-472", name: "name-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
