@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultAlertProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultAlertProfileStore = ClinicalOps.newMemoryDefaultAlertProfileStore()
        let item = ClinicalOps.newDefaultAlertProfile("code-637", title: "title-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
