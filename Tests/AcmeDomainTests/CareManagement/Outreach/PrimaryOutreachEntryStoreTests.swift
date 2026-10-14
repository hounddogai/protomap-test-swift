@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryOutreachEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryOutreachEntryStore = CareManagement.newMemoryPrimaryOutreachEntryStore()
        let item = CareManagement.newPrimaryOutreachEntry("code-117", title: "title-219")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
