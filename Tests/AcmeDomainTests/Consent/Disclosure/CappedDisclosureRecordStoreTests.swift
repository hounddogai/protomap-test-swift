@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedDisclosureRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedDisclosureRecordStore = Consent.newMemoryCappedDisclosureRecordStore()
        let item = Consent.newCappedDisclosureRecord("code-148", label: "label-593")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
