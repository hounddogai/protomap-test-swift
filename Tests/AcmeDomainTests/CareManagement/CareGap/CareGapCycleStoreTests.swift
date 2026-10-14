@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapCycleStore = CareManagement.newMemoryCareGapCycleStore()
        let item = CareManagement.newCareGapCycle("code-302", title: "title-444")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
