@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertPreferenceStore = ClinicalOps.newMemoryAlertPreferenceStore()
        let item = ClinicalOps.newAlertPreference("code-106", label: "label-226")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
