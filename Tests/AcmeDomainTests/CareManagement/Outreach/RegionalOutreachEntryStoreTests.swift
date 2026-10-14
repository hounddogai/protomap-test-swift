@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalOutreachEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalOutreachEntryStore = CareManagement.newMemoryRegionalOutreachEntryStore()
        let item = CareManagement.newRegionalOutreachEntry("code-745", label: "label-802")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
