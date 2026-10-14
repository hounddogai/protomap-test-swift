@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingProgramNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingProgramNoticeStore = CareManagement.newMemoryPendingProgramNoticeStore()
        let item = CareManagement.newPendingProgramNotice("code-789", name: "name-488")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
