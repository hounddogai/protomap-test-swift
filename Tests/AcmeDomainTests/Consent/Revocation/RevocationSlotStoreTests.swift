@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationSlotStore = Consent.newMemoryRevocationSlotStore()
        let item = Consent.newRevocationSlot("code-947", title: "title-496")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
