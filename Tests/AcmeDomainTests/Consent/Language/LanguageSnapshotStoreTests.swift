@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageSnapshotStore = Consent.newMemoryLanguageSnapshotStore()
        let item = Consent.newLanguageSnapshot("code-260", label: "label-903")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
