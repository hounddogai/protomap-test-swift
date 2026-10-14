@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyScheduleStore = Consent.newMemoryProxyScheduleStore()
        let item = Consent.newProxySchedule("code-94", title: "title-79")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
