@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessThresholdStore = Consent.newMemoryWitnessThresholdStore()
        let item = Consent.newWitnessThreshold("code-324", title: "title-216")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
