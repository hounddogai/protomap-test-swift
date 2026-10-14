@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureNoticeStore = Consent.newMemoryDisclosureNoticeStore()
        let item = Consent.newDisclosureNotice("code-788", title: "title-294")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
