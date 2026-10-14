@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachMappingStore = CareManagement.newMemoryOutreachMappingStore()
        let item = CareManagement.newOutreachMapping("code-74", title: "title-403")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
