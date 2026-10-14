@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackAlertOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackAlertOverrideStore = ClinicalOps.newMemoryFallbackAlertOverrideStore()
        let item = ClinicalOps.newFallbackAlertOverride("code-929", title: "title-599")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
