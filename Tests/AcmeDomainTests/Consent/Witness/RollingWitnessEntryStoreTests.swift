@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingWitnessEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingWitnessEntryStore = Consent.newMemoryRollingWitnessEntryStore()
        let item = Consent.newRollingWitnessEntry("code-374", name: "name-653")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
