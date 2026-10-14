@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachSummaryStore = CareManagement.newMemoryOutreachSummaryStore()
        let item = CareManagement.newOutreachSummary("code-703", title: "title-697")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
