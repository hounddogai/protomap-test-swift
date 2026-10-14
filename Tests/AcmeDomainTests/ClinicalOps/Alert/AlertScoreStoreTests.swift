@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertScoreStore = ClinicalOps.newMemoryAlertScoreStore()
        let item = ClinicalOps.newAlertScore("code-645", title: "title-988")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
