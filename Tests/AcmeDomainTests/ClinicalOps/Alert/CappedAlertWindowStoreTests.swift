@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedAlertWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedAlertWindowStore = ClinicalOps.newMemoryCappedAlertWindowStore()
        let item = ClinicalOps.newCappedAlertWindow("code-87", label: "label-810")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
