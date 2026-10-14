@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramQuotaStore = CareManagement.newMemoryProgramQuotaStore()
        let item = CareManagement.newProgramQuota("code-766", name: "name-849")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
