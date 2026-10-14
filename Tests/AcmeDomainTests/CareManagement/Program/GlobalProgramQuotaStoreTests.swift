@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalProgramQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalProgramQuotaStore = CareManagement.newMemoryGlobalProgramQuotaStore()
        let item = CareManagement.newGlobalProgramQuota("code-503", title: "title-363")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
