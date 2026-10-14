@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalTaskScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalTaskScheduleStore = ClinicalOps.newMemoryGlobalTaskScheduleStore()
        let item = ClinicalOps.newGlobalTaskSchedule("code-562", label: "label-66")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
