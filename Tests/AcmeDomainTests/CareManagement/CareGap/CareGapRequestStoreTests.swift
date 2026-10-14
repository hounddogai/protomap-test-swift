@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapRequestStore = CareManagement.newMemoryCareGapRequestStore()
        let item = CareManagement.newCareGapRequest("code-202", name: "name-374")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
