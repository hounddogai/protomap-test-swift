@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguagePlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguagePlanStore = Consent.newMemoryLanguagePlanStore()
        let item = Consent.newLanguagePlan("code-357", name: "name-71")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
