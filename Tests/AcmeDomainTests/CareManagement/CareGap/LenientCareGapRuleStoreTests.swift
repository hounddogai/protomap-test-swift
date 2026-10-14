@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLenientCareGapRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LenientCareGapRuleStore = CareManagement.newMemoryLenientCareGapRuleStore()
        let item = CareManagement.newLenientCareGapRule("code-913", name: "name-748")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
