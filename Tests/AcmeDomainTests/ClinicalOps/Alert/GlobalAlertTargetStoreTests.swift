@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalAlertTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalAlertTargetStore = ClinicalOps.newMemoryGlobalAlertTargetStore()
        let item = ClinicalOps.newGlobalAlertTarget("code-784", label: "label-341")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
