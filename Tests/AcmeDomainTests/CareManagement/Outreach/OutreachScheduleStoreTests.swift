@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachScheduleStore = CareManagement.newMemoryOutreachScheduleStore()
        let item = CareManagement.newOutreachSchedule("code-311", name: "name-775")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
