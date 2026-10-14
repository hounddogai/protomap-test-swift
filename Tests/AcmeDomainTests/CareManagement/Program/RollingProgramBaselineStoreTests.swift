@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingProgramBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingProgramBaselineStore = CareManagement.newMemoryRollingProgramBaselineStore()
        let item = CareManagement.newRollingProgramBaseline("code-907", title: "title-15")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
