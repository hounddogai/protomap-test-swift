@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryGlobalCredentialMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.GlobalCredentialMilestoneStore = Staffing.newMemoryGlobalCredentialMilestoneStore()
        let item = Staffing.newGlobalCredentialMilestone("code-137", title: "title-408")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
