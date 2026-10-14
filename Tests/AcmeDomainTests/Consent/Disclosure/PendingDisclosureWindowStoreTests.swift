@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingDisclosureWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingDisclosureWindowStore = Consent.newMemoryPendingDisclosureWindowStore()
        let item = Consent.newPendingDisclosureWindow("code-578", name: "name-613")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
