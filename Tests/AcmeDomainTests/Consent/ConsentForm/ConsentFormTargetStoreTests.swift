@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormTargetStore = Consent.newMemoryConsentFormTargetStore()
        let item = Consent.newConsentFormTarget("code-380", name: "name-123")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
