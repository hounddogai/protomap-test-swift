@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackLanguagePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackLanguagePlanStore = Consent.newMemoryFallbackLanguagePlanStore()
        let item = Consent.newFallbackLanguagePlan("code-466", title: "title-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
