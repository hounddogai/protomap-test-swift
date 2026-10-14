@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledRiskScoreLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledRiskScoreLedgerStore = CareManagement.newMemoryScheduledRiskScoreLedgerStore()
        let item = CareManagement.newScheduledRiskScoreLedger("code-57", title: "title-160")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
