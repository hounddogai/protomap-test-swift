@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyConsentFormRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyConsentFormRequestStore = Consent.newMemoryLegacyConsentFormRequestStore()
        let item = Consent.newLegacyConsentFormRequest("code-929", label: "label-321")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
