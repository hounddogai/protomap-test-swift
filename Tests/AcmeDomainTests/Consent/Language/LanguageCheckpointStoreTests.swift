@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageCheckpointStore = Consent.newMemoryLanguageCheckpointStore()
        let item = Consent.newLanguageCheckpoint("code-173", name: "name-734")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
