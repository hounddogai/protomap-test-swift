@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessRequestStore = Consent.newMemoryWitnessRequestStore()
        let item = Consent.newWitnessRequest("code-154", name: "name-639")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
