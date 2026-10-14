@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachTierStore = CareManagement.newMemoryOutreachTierStore()
        let item = CareManagement.newOutreachTier("code-371", title: "title-271")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
