@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalCareGapOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalCareGapOverrideStore = CareManagement.newMemoryGlobalCareGapOverrideStore()
        let item = CareManagement.newGlobalCareGapOverride("code-681", name: "name-36")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
