@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalTaskOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalTaskOverrideStore = ClinicalOps.newMemoryGlobalTaskOverrideStore()
        let item = ClinicalOps.newGlobalTaskOverride("code-174", title: "title-344")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
