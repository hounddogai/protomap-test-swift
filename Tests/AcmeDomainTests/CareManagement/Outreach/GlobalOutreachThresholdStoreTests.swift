@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalOutreachThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalOutreachThresholdStore = CareManagement.newMemoryGlobalOutreachThresholdStore()
        let item = CareManagement.newGlobalOutreachThreshold("code-670", name: "name-883")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
