@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachVarianceStore = CareManagement.newMemoryOutreachVarianceStore()
        let item = CareManagement.newOutreachVariance("code-426", name: "name-779")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
