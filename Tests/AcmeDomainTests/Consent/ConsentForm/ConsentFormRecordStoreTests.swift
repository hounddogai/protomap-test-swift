@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormRecordStore = Consent.newMemoryConsentFormRecordStore()
        let item = Consent.newConsentFormRecord("code-821", label: "label-682")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
