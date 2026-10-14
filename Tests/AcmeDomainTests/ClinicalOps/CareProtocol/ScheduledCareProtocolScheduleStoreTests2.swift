@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryScheduledCareProtocolScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.ScheduledCareProtocolScheduleStore = ClinicalOps.newMemoryScheduledCareProtocolScheduleStore()
        let item = ClinicalOps.newScheduledCareProtocolSchedule("code-827", name: "name-37")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
