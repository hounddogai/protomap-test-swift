@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientLanguageCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientLanguageCheckpointStore = Consent.newMemoryLenientLanguageCheckpointStore()
        let item = Consent.newLenientLanguageCheckpoint("code-99", title: "title-455")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
