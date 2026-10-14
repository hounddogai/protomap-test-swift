@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingWitnessWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingWitnessWindowStore = Consent.newMemoryPendingWitnessWindowStore()
        let item = Consent.newPendingWitnessWindow("code-516", label: "label-174")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
