@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalRiskScoreTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalRiskScoreTierStore = CareManagement.newMemoryGlobalRiskScoreTierStore()
        let item = CareManagement.newGlobalRiskScoreTier("code-451", title: "title-304")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
