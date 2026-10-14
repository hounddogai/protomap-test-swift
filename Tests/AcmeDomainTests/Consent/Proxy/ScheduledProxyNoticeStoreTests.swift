@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledProxyNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledProxyNoticeStore = Consent.newMemoryScheduledProxyNoticeStore()
        let item = Consent.newScheduledProxyNotice("code-744", title: "title-159")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
