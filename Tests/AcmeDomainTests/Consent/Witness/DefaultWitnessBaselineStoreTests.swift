@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultWitnessBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultWitnessBaselineStore = Consent.newMemoryDefaultWitnessBaselineStore()
        let item = Consent.newDefaultWitnessBaseline("code-577", name: "name-896")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
