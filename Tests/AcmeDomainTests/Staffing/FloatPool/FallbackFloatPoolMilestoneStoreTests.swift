@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackFloatPoolMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackFloatPoolMilestoneStore = Staffing.newMemoryFallbackFloatPoolMilestoneStore()
        let item = Staffing.newFallbackFloatPoolMilestone("code-45", name: "name-414")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
