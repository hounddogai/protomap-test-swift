@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredOutreachEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredOutreachEntryStore = CareManagement.newMemoryTieredOutreachEntryStore()
        let item = CareManagement.newTieredOutreachEntry("code-989", name: "name-431")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
