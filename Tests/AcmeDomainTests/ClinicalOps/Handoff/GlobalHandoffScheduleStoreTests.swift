@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalHandoffScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalHandoffScheduleStore = ClinicalOps.newMemoryGlobalHandoffScheduleStore()
        let item = ClinicalOps.newGlobalHandoffSchedule("code-945", name: "name-210")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
