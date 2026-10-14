@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryBatchedWitnessAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.BatchedWitnessAdjustmentStore = Consent.newMemoryBatchedWitnessAdjustmentStore()
        let item = Consent.newBatchedWitnessAdjustment("code-386", label: "label-673")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
