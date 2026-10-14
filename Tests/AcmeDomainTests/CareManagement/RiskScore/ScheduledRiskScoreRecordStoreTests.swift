@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledRiskScoreRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledRiskScoreRecordStore = CareManagement.newMemoryScheduledRiskScoreRecordStore()
        let item = CareManagement.newScheduledRiskScoreRecord("code-12", label: "label-545")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
