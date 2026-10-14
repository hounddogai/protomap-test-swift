@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertTargetStore = ClinicalOps.newMemoryAlertTargetStore()
        let item = ClinicalOps.newAlertTarget("code-886", label: "label-242")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
