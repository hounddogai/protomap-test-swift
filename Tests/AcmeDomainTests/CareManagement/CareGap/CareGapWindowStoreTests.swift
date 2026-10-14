@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapWindowStore = CareManagement.newMemoryCareGapWindowStore()
        let item = CareManagement.newCareGapWindow("code-80", name: "name-278")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
