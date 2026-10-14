@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedRiskScoreWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedRiskScoreWindowStore = CareManagement.newMemoryCappedRiskScoreWindowStore()
        let item = CareManagement.newCappedRiskScoreWindow("code-318", title: "title-111")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
