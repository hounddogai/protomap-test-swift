@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictTaskPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictTaskPreferenceStore = ClinicalOps.newMemoryStrictTaskPreferenceStore()
        let item = ClinicalOps.newStrictTaskPreference("code-850", label: "label-814")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
