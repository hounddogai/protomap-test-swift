@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessProfileStore = Consent.newMemoryWitnessProfileStore()
        let item = Consent.newWitnessProfile("code-240", label: "label-744")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
