@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedWitnessNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedWitnessNoticeStore = Consent.newMemoryBatchedWitnessNoticeStore()
        let item = Consent.newBatchedWitnessNotice("code-31", label: "label-159")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
