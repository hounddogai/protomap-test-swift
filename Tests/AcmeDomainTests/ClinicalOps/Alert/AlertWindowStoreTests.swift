@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertWindowStore = ClinicalOps.newMemoryAlertWindowStore()
        let item = ClinicalOps.newAlertWindow("code-476", title: "title-819")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
