@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingPreferenceStore = ClinicalOps.newMemoryRoundingPreferenceStore()
        let item = ClinicalOps.newRoundingPreference("code-182", label: "label-669")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
