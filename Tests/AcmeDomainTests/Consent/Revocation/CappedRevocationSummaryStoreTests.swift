@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedRevocationSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedRevocationSummaryStore = Consent.newMemoryCappedRevocationSummaryStore()
        let item = Consent.newCappedRevocationSummary("code-547", label: "label-78")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
