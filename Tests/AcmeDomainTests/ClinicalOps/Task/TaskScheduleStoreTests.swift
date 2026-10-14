@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskScheduleStore = ClinicalOps.newMemoryTaskScheduleStore()
        let item = ClinicalOps.newTaskSchedule("code-651", name: "name-262")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
