@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultRiskScoreWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultRiskScoreWindowStore = CareManagement.newMemoryDefaultRiskScoreWindowStore()
        let item = CareManagement.newDefaultRiskScoreWindow("code-916", title: "title-530")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
