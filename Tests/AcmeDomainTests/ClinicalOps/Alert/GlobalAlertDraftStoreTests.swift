@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalAlertDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalAlertDraftStore = ClinicalOps.newMemoryGlobalAlertDraftStore()
        let item = ClinicalOps.newGlobalAlertDraft("code-729", name: "name-381")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
