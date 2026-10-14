@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryDisclosureRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryDisclosureRecordStore = Consent.newMemoryPrimaryDisclosureRecordStore()
        let item = Consent.newPrimaryDisclosureRecord("code-562", name: "name-113")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
