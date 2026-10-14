@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessWindowStore = Consent.newMemoryWitnessWindowStore()
        let item = Consent.newWitnessWindow("code-33", label: "label-242")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
