@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalLanguageCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalLanguageCheckpointStore = Consent.newMemorySeasonalLanguageCheckpointStore()
        let item = Consent.newSeasonalLanguageCheckpoint("code-121", title: "title-763")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
