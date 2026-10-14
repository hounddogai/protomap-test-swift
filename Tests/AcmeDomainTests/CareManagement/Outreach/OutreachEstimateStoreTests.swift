@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachEstimateStore = CareManagement.newMemoryOutreachEstimateStore()
        let item = CareManagement.newOutreachEstimate("code-490", name: "name-771")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
