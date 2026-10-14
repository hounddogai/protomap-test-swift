@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapGroupStore = CareManagement.newMemoryCareGapGroupStore()
        let item = CareManagement.newCareGapGroup("code-661", label: "label-75")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
