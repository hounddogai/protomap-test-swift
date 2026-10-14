@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalAlertSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalAlertSnapshotStore = ClinicalOps.newMemoryRegionalAlertSnapshotStore()
        let item = ClinicalOps.newRegionalAlertSnapshot("code-285", label: "label-675")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
