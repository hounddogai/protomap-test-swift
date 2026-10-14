@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessReviewStore = Consent.newMemoryWitnessReviewStore()
        let item = Consent.newWitnessReview("code-475", name: "name-907")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
