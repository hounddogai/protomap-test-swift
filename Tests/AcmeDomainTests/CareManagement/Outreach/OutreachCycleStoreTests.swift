@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachCycleStore = CareManagement.newMemoryOutreachCycleStore()
        let item = CareManagement.newOutreachCycle("code-330", name: "name-124")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
