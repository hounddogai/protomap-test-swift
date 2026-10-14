@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingCareGapScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingCareGapScheduleStore = CareManagement.newMemoryRollingCareGapScheduleStore()
        let item = CareManagement.newRollingCareGapSchedule("code-810", title: "title-634")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
