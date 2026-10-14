@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureSummaryStore = Consent.newMemoryDisclosureSummaryStore()
        let item = Consent.newDisclosureSummary("code-961", label: "label-148")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
