@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultRiskScoreThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultRiskScoreThresholdStore = CareManagement.newMemoryDefaultRiskScoreThresholdStore()
        let item = CareManagement.newDefaultRiskScoreThreshold("code-633", title: "title-406")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
