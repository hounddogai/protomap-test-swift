@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyTaskScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyTaskScheduleStore = ClinicalOps.newMemoryLegacyTaskScheduleStore()
        let item = ClinicalOps.newLegacyTaskSchedule("code-192", title: "title-430")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
