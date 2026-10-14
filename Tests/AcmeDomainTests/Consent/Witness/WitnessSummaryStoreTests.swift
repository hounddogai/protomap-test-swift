@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessSummaryStore = Consent.newMemoryWitnessSummaryStore()
        let item = Consent.newWitnessSummary("code-524", label: "label-686")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
