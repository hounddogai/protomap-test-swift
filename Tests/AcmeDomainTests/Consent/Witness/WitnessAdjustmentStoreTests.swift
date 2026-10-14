@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessAdjustmentStore = Consent.newMemoryWitnessAdjustmentStore()
        let item = Consent.newWitnessAdjustment("code-961", title: "title-51")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
