@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingScheduleStore = ClinicalOps.newMemoryRoundingScheduleStore()
        let item = ClinicalOps.newRoundingSchedule("code-999", title: "title-301")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
