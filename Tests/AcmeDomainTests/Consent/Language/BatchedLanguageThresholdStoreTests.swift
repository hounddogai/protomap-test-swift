@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedLanguageThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedLanguageThresholdStore = Consent.newMemoryBatchedLanguageThresholdStore()
        let item = Consent.newBatchedLanguageThreshold("code-603", label: "label-531")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
