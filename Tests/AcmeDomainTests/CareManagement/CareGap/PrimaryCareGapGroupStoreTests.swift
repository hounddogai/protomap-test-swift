@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryCareGapGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryCareGapGroupStore = CareManagement.newMemoryPrimaryCareGapGroupStore()
        let item = CareManagement.newPrimaryCareGapGroup("code-638", label: "label-609")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
